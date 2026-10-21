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
        "recorder": recorderC,
        "denoise": denoiseC,
        "color": colorC,
        "looks": looksC,
        "scopes": scopesC,
        "undoHistory": historyC,
        "sourceViewer": sourceViewerC,
        "agentLog": agentLogC
    })

    Component { id: assetsC; AssetsPanel {} }
    Component { id: propertiesC; PropertiesPanel {} }
    Component { id: previewC; PreviewPanel {} }
    Component { id: timelineC; TimelinePanel {} }
    Component { id: audioMixerC; AudioMixerPanel {} }
    Component { id: subtitlesC; SubtitlesPanel {} }
    Component { id: recorderC; RecorderPanel {} }
    Component { id: denoiseC; DenoisePanel {} }
    Component { id: colorC; ColorPanel {} }
    Component { id: looksC; LooksPanel {} }
    Component { id: scopesC; ScopesPanel {} }
    Component { id: historyC; HistoryPanel {} }
    Component { id: sourceViewerC; SourceViewerPanel {} }
    Component { id: agentLogC; AgentLogPanel {} }
    Component { id: placeholderC; WorkspacePlaceholderPanel {} }

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
            item.keyframesTab = Qt.binding(() => root.propertiesPanel?.keyframesTab ?? false)
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
        }
        return item
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
