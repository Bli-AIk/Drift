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
    radius: Theme.radiusSm
    color: actionArea.containsMouse ? Theme.accent : "transparent"

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        IconGlyph {
            id: rowIcon
            iconSize: Theme.iconSizeMd
            iconColor: Theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: rowLabel
            color: Theme.foreground
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
