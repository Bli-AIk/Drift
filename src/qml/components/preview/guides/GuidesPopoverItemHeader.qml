import QtQuick
import Drift
// Kind title plus lock and remove for one guide item.
Item {
    id: header

    required property var item
    required property bool editable
    signal lockToggled()
    signal removeRequested()

    width: parent ? parent.width : 0
    height: Theme.iconButtonSize

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: header.item.kind === "v" ? qsTr("Vertical line")
              : header.item.kind === "h" ? qsTr("Horizontal line")
              : header.item.kind === "rect" ? qsTr("Margins")
              : qsTr("Aspect frame")
        color: Theme.c.guidesPopoverItemHeader.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        font.weight: Font.Medium
    }

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: header.editable

        IconButton {
            glyph: header.item.locked ? Theme.icons.lock : Theme.icons.lockOpen
            tooltip: header.item.locked ? qsTr("Unlock so it can be dragged on the preview")
                                       : qsTr("Lock so it cannot be dragged on the preview")
            active: header.item.locked
            onClicked: header.lockToggled()
        }
        IconButton {
            glyph: Theme.icons.trash
            tooltip: qsTr("Remove guide")
            onClicked: header.removeRequested()
        }
    }
}
