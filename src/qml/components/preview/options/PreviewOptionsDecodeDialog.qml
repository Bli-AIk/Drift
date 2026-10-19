import QtQuick
import Drift
// Picking a decoder that runs on the other GPU is a legitimate choice — some codecs only the
// discrete card decodes — so this explains the cost rather than blocking it, and offers the
// change that would actually fix it where Drift can make one.
ThemedDialog {
    id: decodeGpuDialog

    property var mode: null

    // The combo already moved its own highlight; the menu puts it back on what is still in use.
    signal restoreSelection()

    function confirm(pending) {
        mode = pending
        open()
    }

    title: qsTr("Decoding on a different graphics card")
    preferredWidth: Theme.dialogWidthMd
    acceptText: qsTr("Use anyway")
    rejectText: qsTr("Cancel")
    // Destructive-ish in the sense that matters here: Enter should not commit a choice the
    // user opened this dialog to understand.
    acceptOnReturn: false

    onAccepted: if (mode) EditorState.playback.decodeMode = mode.id
    onRejected: decodeGpuDialog.restoreSelection()

    contentItem: Column {
        spacing: Theme.spacingLg

        ThemedLabel {
            width: parent.width
            tone: "default"
            size: "sm"
            text: decodeGpuDialog.mode ? decodeGpuDialog.mode.note : ""
        }

        ThemedLabel {
            width: parent.width
            visible: !EditorState.preferences.gpuPreferenceSupported && Qt.platform.os === "linux"
            text: qsTr("Launching Drift with prime-run (or DRI_PRIME=1) puts OpenGL on the "
                       + "same card as the decoder.")
        }

        ThemedButton {
            visible: EditorState.preferences.gpuPreferenceSupported
            text: qsTr("Run Drift on the high-performance graphics card")
            variant: "secondary"
            // Leaves the decode mode alone: this is the other way out, not a confirmation.
            onClicked: {
                EditorState.preferences.preferredGpu = "discrete"
                decodeGpuDialog.reject()
            }
        }

        ThemedLabel {
            width: parent.width
            visible: EditorState.preferences.gpuPreferenceInSystemSettings
            text: qsTr("Set Drift to High performance in Windows Settings > Display > Graphics, "
                       + "then restart Drift.")
        }

        ThemedButton {
            visible: EditorState.preferences.gpuPreferenceInSystemSettings
            text: qsTr("Open graphics settings")
            variant: "secondary"
            onClicked: {
                Qt.openUrlExternally("ms-settings:display-advancedgraphics")
                decodeGpuDialog.reject()
            }
        }
    }
}
