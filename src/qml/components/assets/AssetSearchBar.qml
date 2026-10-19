import QtQuick
import Drift
// Top row of the catalog tabs: the search field, which also names the tab (these tabs
// have no panel header), with the tab's actions as icon buttons at its right end.
Item {
    id: root

    property alias text: field.text
    property alias placeholderText: field.placeholderText
    default property alias actions: actionRow.data

    width: parent ? parent.width : 0
    implicitHeight: Theme.pagePadding + Theme.controlHeight
    height: implicitHeight

    ThemedTextField {
        id: field
        x: Theme.pagePadding
        y: Theme.pagePadding
        width: root.width - Theme.pagePadding * 2
               - (actionRow.width > 0 ? actionRow.width + Theme.spacingSm : 0)
        font.family: Theme.fontFamily
    }

    Row {
        id: actionRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.pagePadding
        y: Theme.pagePadding
        height: Theme.controlHeight
        spacing: Theme.spacingXs
    }
}
