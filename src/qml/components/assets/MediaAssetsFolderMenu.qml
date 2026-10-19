import QtQuick
import Drift
// Context menu for a bin folder tile, shared by the grid card and the list row.
ThemedContextMenu {
    id: root

    required property MediaAssetsTab host
    required property string folderId
    required property string folderName

    ThemedMenuItem {
        text: qsTr("Open")
        icon.name: Theme.icons.folder
        onTriggered: EditorState.bin.currentFolderId = root.folderId
    }
    ThemedMenuItem {
        text: qsTr("Rename…")
        icon.name: Theme.icons.pencil
        onTriggered: root.host.folderRenameRequested(root.folderId, root.folderName)
    }
    ThemedMenuItem {
        text: qsTr("Move to folder…")
        icon.name: Theme.icons.folder
        onTriggered: root.host.folderMoveRequested(root.folderId)
    }
    ThemedMenuSeparator { }
    ThemedMenuItem {
        text: qsTr("Delete")
        icon.name: Theme.icons.trash
        onTriggered: EditorState.bin.deleteFolder(root.folderId)
    }
}
