import QtQuick
import Drift

// Every panel instance lives here for the whole session. A layout rebuild only moves
// them between slots and this hidden holder; destroying one would take the preview's
// video sink and GL renderer with it.
Item {
    id: root
    visible: false

    property var assetsPanel: null
    property var propertiesPanel: null
    property var previewPanel: null
    property var timelinePanel: null
    property var audioMixerPanel: null
    property var sourceViewerPanel: null
    property var denoisePanel: null
    property var colorPanel: null
    property var looksPanel: null
    property var scopesPanel: null
    property var keyframesPanel: null
    property var subtitlesPanel: null
    property var subtitleLanePanel: null
    property var subtitleTextPanel: null
    property var subtitleTimingPanel: null

    property var _created: ({})

    // Parked panels keep visible=true but sit under the hidden holder, so parent is the test.
    readonly property bool audioMixerShown: !!root.audioMixerPanel
                                            && root.audioMixerPanel.visible
                                            && root.audioMixerPanel.parent !== root

    readonly property bool sourceViewerShown: !!root.sourceViewerPanel
                                              && root.sourceViewerPanel.visible
                                              && root.sourceViewerPanel.parent !== root

    readonly property bool denoiseInLayout: !!root.denoisePanel && root.denoisePanel.parent !== root

    readonly property bool denoiseShown: !!root.denoisePanel
                                         && root.denoisePanel.visible
                                         && root.denoisePanel.parent !== root

    readonly property bool colorShown: !!root.colorPanel
                                       && root.colorPanel.visible
                                       && root.colorPanel.parent !== root

    readonly property bool looksShown: !!root.looksPanel
                                       && root.looksPanel.visible
                                       && root.looksPanel.parent !== root

    readonly property bool scopesShown: !!root.scopesPanel
                                        && root.scopesPanel.visible
                                        && root.scopesPanel.parent !== root

    readonly property bool keyframesShown: !!root.keyframesPanel
                                           && root.keyframesPanel.visible
                                           && root.keyframesPanel.parent !== root

    readonly property bool subtitlesShown: !!root.subtitlesPanel
                                           && root.subtitlesPanel.visible
                                           && root.subtitlesPanel.parent !== root

    readonly property bool subtitleLaneShown: !!root.subtitleLanePanel
                                              && root.subtitleLanePanel.visible
                                              && root.subtitleLanePanel.parent !== root

    readonly property bool subtitleTextShown: !!root.subtitleTextPanel
                                              && root.subtitleTextPanel.visible
                                              && root.subtitleTextPanel.parent !== root

    readonly property bool subtitleTimingShown: !!root.subtitleTimingPanel
                                                && root.subtitleTimingPanel.visible
                                                && root.subtitleTimingPanel.parent !== root

    // One line per panel type. A type missing from here gets a placeholder.
    // "assets.<tab>" and "properties.<tab>" are handled by prefix in panel(): the full panels
    // pinned to one tab.
    readonly property var factories: ({
        "assets": assetsC,
        "properties": propertiesC,
        "preview": previewC,
        "timeline": timelineC,
        "audioMixer": audioMixerC,
        "subtitles": subtitlesC,
        "subtitleLane": subtitleLaneC,
        "subtitleText": subtitleTextC,
        "subtitleTiming": subtitleTimingC,
        "recorder": recorderC,
        "denoise": denoiseC,
        "color": colorC,
        "looks": looksC,
        "scopes": scopesC,
        "keyframes": keyframesC,
        "undoHistory": historyC,
        "sourceViewer": sourceViewerC,
        "agentLog": agentLogC
    })

    Component { id: assetsC; AssetsPanel {} }
    Component { id: propertiesC; PropertiesPanel {} }
    Component { id: previewC; PreviewPanel {} }
    Component { id: timelineC; TimelinePanel {} }
    Component { id: audioMixerC; AudioMixerPanel {} }
    Component { id: subtitlesC; LazyPanel { panel: SubtitlesPanel {} } }
    Component { id: subtitleLaneC; LazyPanel { panel: SubtitleLanePanel {} } }
    Component { id: subtitleTextC; LazyPanel { panel: SubtitleTextPanel {} } }
    Component { id: subtitleTimingC; LazyPanel { panel: SubtitleTimingPanel {} } }
    Component { id: recorderC; RecorderPanel {} }
    Component { id: denoiseC; DenoisePanel {} }
    Component { id: colorC; ColorPanel {} }
    Component { id: looksC; LooksPanel {} }
    Component { id: scopesC; ScopesPanel {} }
    Component { id: keyframesC; KeyframesPanel {} }
    Component { id: historyC; HistoryPanel {} }
    Component { id: sourceViewerC; SourceViewerPanel {} }
    Component { id: agentLogC; AgentLogPanel {} }
    Component { id: placeholderC; WorkspacePlaceholderPanel {} }

    // Stays in the pool like any panel, but its content only exists while shown: a parked or
    // background-tab panel keeps no bindings alive.
    component LazyPanel: Item {
        id: lazy

        property bool shown: false
        property Component panel: null

        Loader {
            anchors.fill: parent
            active: lazy.shown
            sourceComponent: lazy.panel
            onLoaded: item.shown = Qt.binding(() => lazy.shown)
        }
    }

    function label(type) {
        const types = Workspaces.panelTypes
        for (let i = 0; i < types.length; ++i) {
            if (types[i].type === type)
                return types[i].fullLabel
        }
        return type
    }

    function create(type) {
        if (type.startsWith("assets."))
            return assetsC.createObject(root, { lockedTab: type.slice(7) })
        if (type.startsWith("properties.")) {
            const pane = propertiesC.createObject(root, { lockedTab: type.slice(11) })
            pane.browseEffectsRequested.connect(root.browseEffects)
            pane.browseAudioEffectsRequested.connect(root.browseAudioEffects)
            return pane
        }
        const factory = root.factories[type]
        return factory ? factory.createObject(root)
                       : placeholderC.createObject(root, { label: root.label(type) })
    }

    function browseEffects() { root.assetsPanel?.showTab("effects") }
    function browseAudioEffects() { root.assetsPanel?.showTab("sounds") }

    function panel(type) {
        if (root._created[type])
            return root._created[type]
        const item = root.create(type)
        root._created[type] = item
        switch (type) {
        case "assets":
            root.assetsPanel = item
            break
        case "properties":
            root.propertiesPanel = item
            break
        case "preview":
            root.previewPanel = item
            item.previewFullscreen = Qt.binding(() => ShellBridge.main?.previewFullscreen ?? false)
            break
        case "timeline":
            root.timelinePanel = item
            item.keyframesTab = Qt.binding(() => (root.propertiesPanel?.keyframesTab ?? false) && !root.keyframesShown)
            item.externalMixerShown = Qt.binding(() => root.audioMixerShown)
            break
        case "audioMixer":
            root.audioMixerPanel = item
            break
        case "sourceViewer":
            root.sourceViewerPanel = item
            item.shown = Qt.binding(() => root.sourceViewerShown)
            break
        case "denoise":
            root.denoisePanel = item
            item.shown = Qt.binding(() => root.denoiseShown)
            break
        case "color":
            root.colorPanel = item
            item.shown = Qt.binding(() => root.colorShown)
            break
        case "looks":
            root.looksPanel = item
            item.shown = Qt.binding(() => root.looksShown)
            break
        case "scopes":
            root.scopesPanel = item
            item.shown = Qt.binding(() => root.scopesShown)
            break
        case "keyframes":
            root.keyframesPanel = item
            item.shown = Qt.binding(() => root.keyframesShown)
            break
        case "subtitles":
            root.subtitlesPanel = item
            item.shown = Qt.binding(() => root.subtitlesShown)
            break
        case "subtitleLane":
            root.subtitleLanePanel = item
            item.shown = Qt.binding(() => root.subtitleLaneShown)
            break
        case "subtitleText":
            root.subtitleTextPanel = item
            item.shown = Qt.binding(() => root.subtitleTextShown)
            break
        case "subtitleTiming":
            root.subtitleTimingPanel = item
            item.shown = Qt.binding(() => root.subtitleTimingShown)
            break
        }
        return item
    }

    // Turns on the timeline's cue lane (SubtitleCueLane) while any subtitle panel is on screen.
    Binding {
        target: EditorState
        property: "subtitleEditing"
        value: true
        when: root.subtitlesShown || root.subtitleLaneShown || root.subtitleTextShown || root.subtitleTimingShown
        restoreMode: Binding.RestoreBindingOrValue
    }

    function parkAll() {
        for (const type in root._created) {
            const item = root._created[type]
            item.anchors.fill = null
            item.parent = root
        }
    }

    Component.onCompleted: root.panel("preview")

    Connections {
        target: root.propertiesPanel
        // Empty-state browse CTAs jump the assets panel to the matching library tab.
        function onBrowseEffectsRequested() { root.browseEffects() }
        function onBrowseAudioEffectsRequested() { root.browseAudioEffects() }
    }

    Connections {
        target: root.previewPanel
        function onFullscreenRequested() { ShellBridge.main.togglePreviewFullscreen() }
    }
}
