import QtQuick
import Drift

// Confirms deleting the track the header menu targeted.
ThemedDialog {
    id: confirmDeleteTrack

    property var column
    title: qsTr("Delete this track?")
    acceptText: qsTr("Delete track")
    acceptVariant: "destructive"
    preferredWidth: Theme.dialogWidthSm
    acceptOnReturn: false

    readonly property int clipCount: {
        if (column.pendingDeleteTrack < 0 || column.pendingDeleteTrack >= column.tracks.length)
            return 0
        const clips = column.tracks[column.pendingDeleteTrack].clips
        return clips ? clips.length : 0
    }

    contentItem: ThemedLabel {
        width: parent ? parent.width : Theme.dialogWidthSm
        wrapMode: Text.WordWrap
        size: "sm"
        text: confirmDeleteTrack.clipCount > 0
              ? qsTr("This removes the track and its %n clips. You can undo afterwards.",
                     "", confirmDeleteTrack.clipCount)
              : qsTr("This removes the empty track. You can undo afterwards.")
    }

    onAccepted: {
        if (column.pendingDeleteTrack >= 0)
            EditorState.removeTrack(column.pendingDeleteTrack)
        column.pendingDeleteTrack = -1
    }
    onRejected: column.pendingDeleteTrack = -1
}
