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

    property var _created: ({})

    // Parked panels keep visible=true but sit under the hidden holder, so parent is the test.
    readonly property bool audioMixerShown: !!root.audioMixerPanel
                                            && root.audioMixerPanel.visible
                                            && root.audioMixerPanel.parent !== root

    readonly property bool sourceViewerShown: !!root.sourceViewerPanel
                                              && root.sourceViewerPanel.visible
                                              && root.sourceViewerPanel.parent !== root

    // One line per panel type. A type missing from here gets a placeholder.
    readonly property var factories: ({
        "assets": assetsC,
        "properties": propertiesC,
        "preview": previewC,
        "timeline": timelineC,
        "audioMixer": audioMixerC,
        "subtitles": subtitlesC,
        "recorder": recorderC,
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
    Component { id: historyC; HistoryPanel {} }
    Component { id: sourceViewerC; SourceViewerPanel {} }
    Component { id: agentLogC; AgentLogPanel {} }
    Component { id: placeholderC; WorkspacePlaceholderPanel {} }

    function label(type) {
        const types = Workspaces.panelTypes
        for (let i = 0; i < types.length; ++i) {
            if (types[i].type === type)
                return types[i].label
        }
        return type
    }

    function panel(type) {
        if (root._created[type])
            return root._created[type]
        const factory = root.factories[type]
        const item = factory ? factory.createObject(root)
                             : placeholderC.createObject(root, { label: root.label(type) })
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
        function onBrowseEffectsRequested() { root.assetsPanel?.showTab("effects") }
        function onBrowseAudioEffectsRequested() { root.assetsPanel?.showTab("sounds") }
    }

    Connections {
        target: root.previewPanel
        function onFullscreenRequested() { ShellBridge.main.togglePreviewFullscreen() }
    }
}
