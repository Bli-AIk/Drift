import QtQuick
import Drift

// One row in the toolbar customize list: an action, a separator, or the More-menu divider.
Rectangle {
    id: row

    property var dialog
    property var view
    property var entryModel
    required property string itemId
    required property int index
    readonly property bool isDivider: itemId === "divider"
    readonly property bool isSeparator: itemId === "separator"

    width: view.width
    height: dialog.rowHeight
    radius: Theme.c.timelineToolbarCustomizeRow.radius
    color: isDivider ? "transparent"
           : (grip.pressed ? Theme.c.timelineToolbarCustomizeRow.backgroundPressed : "transparent")

    TimelineToolbarCustomizeDivider {
        visible: row.isDivider
        anchors.fill: parent
    }

    TimelineToolbarCustomizeGrip {
        id: grip
        visible: !row.isDivider
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        dialog: row.dialog
        view: row.view
        rowIndex: row.index
    }

    IconGlyph {
        id: actionGlyph
        visible: !row.isDivider && !row.isSeparator
        anchors.left: grip.right
        anchors.leftMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        glyph: visible ? row.dialog.toolbar.actionMeta[row.itemId].glyph : ""
        iconSize: Theme.iconSizeBase
        iconColor: Theme.c.timelineToolbarCustomizeRow.icon
    }

    Text {
        visible: !row.isDivider
        anchors.left: row.isSeparator ? grip.right : actionGlyph.right
        anchors.leftMargin: Theme.spacingLg
        anchors.right: rowButtons.left
        anchors.rightMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        text: row.isSeparator ? qsTr("— Separator —")
                              : (row.isDivider ? "" : row.dialog.toolbar.actionMeta[row.itemId].label)
        color: row.isSeparator ? Theme.c.timelineToolbarCustomizeRow.foregroundMuted : Theme.c.timelineToolbarCustomizeRow.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        elide: Text.ElideRight
    }

    Row {
        id: rowButtons
        visible: !row.isDivider
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        IconButton {
            glyph: Theme.icons.chevronUp
            variant: "text"
            tooltip: qsTr("Move up")
            enabled: row.index > 0
            onClicked: row.dialog.moveEntry(row.index, row.index - 1)
        }
        IconButton {
            glyph: Theme.icons.chevronDown
            variant: "text"
            tooltip: qsTr("Move down")
            enabled: row.index < row.entryModel.count - 1
            onClicked: row.dialog.moveEntry(row.index, row.index + 1)
        }
        IconButton {
            visible: row.isSeparator
            glyph: Theme.icons.x
            variant: "text"
            tooltip: qsTr("Remove separator")
            onClicked: row.entryModel.remove(row.index)
        }
    }
}
