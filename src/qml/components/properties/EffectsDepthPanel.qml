import QtQuick
import QtQuick.Window
import Drift

// Depth status and controls for one clip: estimate (draft or high quality), progress, cancel,
// clear, and the download when the model is missing. Used for the selected clip's own depth
// effects and, on the Behind Subject card, for the clip that layer sits inside.
Column {
    id: panel
    property int targetTrack: -1
    property int targetClip: -1
    // Where the depth job is keyed, so progress can be followed.
    property string targetId: ""
    property bool hasDepth: false
    property bool canDepth: true
    property string cannotText: ""
    property string missingText: ""

    // Asked of the engine rather than the addon registry, and reset when an addon lands:
    // the model can equally come from DRIFT_DEPTH_MODEL_DIR.
    property bool runtimeReady: Addons.runtimeAvailable()
    property bool depthReady: EditorState.depth.available() && Addons.runtimeAvailable()
    property bool highQuality: false
    property int jobRevision: 0
    readonly property var job: {
        void panel.jobRevision
        return panel.targetId ? EditorState.depth.job(panel.targetId) : ({})
    }
    readonly property bool running: job.active === true

    spacing: Theme.spacingSm

    Connections {
        target: EditorState.depth
        function onJobChanged(clipId) {
            if (clipId === panel.targetId)
                panel.jobRevision++
        }
    }
    Connections {
        target: Addons
        function onKindChanged(kind) {
            if (kind !== "depth-model" && kind !== "onnxruntime")
                return
            panel.runtimeReady = Addons.runtimeAvailable()
            panel.depthReady = EditorState.depth.available() && panel.runtimeReady
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: !panel.canDepth && panel.cannotText !== ""
        text: panel.cannotText
        color: Theme.c.effectsDepthPanel.warning
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    // The effect is in the stack and doing nothing; without this the preview gives no clue why.
    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: panel.canDepth && panel.depthReady && !panel.hasDepth && !panel.running
        text: panel.missingText
        color: Theme.c.effectsDepthPanel.warning
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: !panel.running && !!panel.job.error
        text: panel.job.error || ""
        color: Theme.c.effectsDepthPanel.destructive
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    ThemedChip {
        visible: panel.canDepth && panel.depthReady && !panel.running
        text: qsTr("High quality")
        tooltip: qsTr("Sharper depth edges, about twice as slow")
        selected: panel.highQuality
        onClicked: panel.highQuality = !panel.highQuality
    }

    ThemedButton {
        visible: panel.canDepth && panel.depthReady && !panel.running
        width: parent.width
        text: panel.hasDepth ? qsTr("Re-estimate depth") : qsTr("Estimate depth")
        variant: panel.hasDepth ? "ghost" : "secondary"
        onClicked: EditorState.depth.estimate(panel.targetTrack, panel.targetClip,
                                              panel.highQuality)
    }

    ThemedButton {
        visible: panel.canDepth && panel.hasDepth && !panel.running
        width: parent.width
        text: qsTr("Clear depth")
        variant: "ghost"
        onClicked: EditorState.depth.clear(panel.targetTrack, panel.targetClip)
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        visible: panel.running
        text: panel.job.status || ""
        color: Theme.c.effectsDepthPanel.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    ThemedProgressBar {
        visible: panel.running
        width: parent.width
        value: panel.job.progress || 0
    }

    ThemedButton {
        visible: panel.running
        width: parent.width
        text: qsTr("Cancel")
        variant: "ghost"
        onClicked: EditorState.depth.cancel(panel.targetId)
    }

    ThemedButton {
        visible: panel.canDepth && !panel.depthReady
        width: parent.width
        text: panel.runtimeReady
              ? qsTr("Download depth estimation (about 160 MB)")
              : qsTr("Install AI engine first")
        variant: "primary"
        // Inline components cannot see the file's ids, so not root.Window.
        onClicked: ShellBridge.main.openAddonManager(
            panel.runtimeReady ? "depth-model" : "onnxruntime")
    }
}
