import QtQuick
import Drift

// Rename dialog for the track under the header that asked.
ThemedDialog {
    id: renameTrackDialog

    property TrackHeaderColumn column
    property alias nameField: renameTrackField
    title: qsTr("Rename track")
    acceptText: qsTr("Rename")
    preferredWidth: Theme.dialogWidthSm

    contentItem: Column {
        width: parent ? parent.width : Theme.dialogWidthSm
        spacing: Theme.spacingMd

        ThemedTextField {
            id: renameTrackField
            width: parent.width
            placeholderText: qsTr("Track name")
        }
    }

    onOpened: {
        renameTrackField.forceActiveFocus()
        renameTrackField.selectAll()
    }
    onAccepted: {
        if (column.pendingRenameTrack >= 0)
            EditorState.renameTrack(column.pendingRenameTrack, renameTrackField.text)
        column.pendingRenameTrack = -1
    }
    onRejected: column.pendingRenameTrack = -1
}
