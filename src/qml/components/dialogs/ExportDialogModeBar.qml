import QtQuick
import Drift

Row {
    required property ExportDialog dialog
    spacing: Theme.spacingMd

    ThemedToggleButton {
        text: qsTr("Video")
        checked: dialog.exportMode === "video"
        onClicked: {
            if (dialog.exportMode === "video")
                return
            dialog.exportMode = "video"
            dialog.advancedOpen = false
            dialog.syncComboIndices()
        }
    }

    ThemedToggleButton {
        text: qsTr("Audio")
        checked: dialog.exportMode === "audio"
        onClicked: {
            if (dialog.exportMode === "audio")
                return
            dialog.exportMode = "audio"
            dialog.advancedOpen = false
            dialog.syncComboIndices()
        }
    }

    ThemedToggleButton {
        text: qsTr("GIF")
        enabled: EditorState.exportGifAvailable()
        tooltip: enabled ? "" : qsTr("GIF encoder is not available in this build")
        checked: dialog.exportMode === "gif"
        onClicked: {
            if (dialog.exportMode === "gif")
                return
            dialog.exportMode = "gif"
            dialog.advancedOpen = false
            dialog.applyGifDefaults()
            dialog.syncComboIndices()
        }
    }
    }
