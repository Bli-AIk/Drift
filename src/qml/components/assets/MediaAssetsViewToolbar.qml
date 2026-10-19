import QtQuick
import Drift
// Grid, list, tree and sort toggles that share the media search row.
Row {
    id: root

    property bool gridMode: false
    property string viewMode: "grid"
    property bool treeMode: false
    property bool sortByKind: false

    signal sortToggled()

    spacing: Theme.spacingSm

    IconButton {
        glyph: Theme.icons.layoutGrid
        variant: "ghost"
        tooltip: qsTr("Grid view")
        active: root.gridMode
        onClicked: EditorState.mediaViewMode = "grid"
    }

    IconButton {
        glyph: Theme.icons.list
        variant: "ghost"
        tooltip: qsTr("List view")
        active: root.viewMode === "list"
        onClicked: EditorState.mediaViewMode = "list"
    }

    IconButton {
        glyph: Theme.icons.listTree
        variant: "ghost"
        tooltip: qsTr("Tree view")
        active: root.treeMode
        onClicked: EditorState.mediaViewMode = "tree"
    }

    IconButton {
        glyph: root.sortByKind ? Theme.icons.sortByKind : Theme.icons.sortByName
        variant: "ghost"
        tooltip: root.sortByKind ? qsTr("Sort by name") : qsTr("Sort by type")
        onClicked: root.sortToggled()
    }
}
