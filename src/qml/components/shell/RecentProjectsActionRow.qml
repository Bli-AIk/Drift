import QtQuick
import QtQuick.Controls.Basic
import Drift

Rectangle {
    property Popup popup
    id: actionRow

    property alias glyph: rowIcon.glyph
    property alias text: rowLabel.text
    signal triggered()

    width: parent ? parent.width : 0
    height: Theme.controlHeight + Theme.spacingSm
    radius: Theme.c.recentProjectsActionRow.radius
    color: actionArea.containsMouse ? Theme.c.recentProjectsActionRow.backgroundHover : "transparent"

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        IconGlyph {
            id: rowIcon
            iconSize: Theme.iconSizeMd
            iconColor: Theme.c.recentProjectsActionRow.icon
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: rowLabel
            color: Theme.c.recentProjectsActionRow.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: actionArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.close()
            actionRow.triggered()
        }
    }
}
