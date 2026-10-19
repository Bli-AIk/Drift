import QtQuick
import Drift

// Context menu for one bookmark flag.
ThemedContextMenu {
    id: menu

    property int bookmarkIndex: -1
    property string bookmarkLabel: ""
    property real bookmarkSeconds: 0

    signal renameRequested(int index, string label)

    ThemedMenuItem {
        text: qsTr("Go to bookmark")
        icon.name: Theme.icons.bookmark
        onTriggered: EditorState.goToBookmark(menu.bookmarkIndex)
    }
    ThemedMenuItem {
        text: qsTr("Rename…")
        onTriggered: menu.renameRequested(menu.bookmarkIndex, menu.bookmarkLabel)
    }
    ThemedMenuSeparator { }
    ThemedMenuItem {
        text: qsTr("Delete")
        icon.name: Theme.icons.trash
        onTriggered: EditorState.removeBookmark(menu.bookmarkIndex)
    }
}
