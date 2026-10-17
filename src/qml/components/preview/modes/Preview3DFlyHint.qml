import QtQuick
import Drift

Rectangle {
    id: hintBox

    required property string message

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.spacingLg
    width: hint.implicitWidth + Theme.spacingLg * 2
    height: hint.implicitHeight + Theme.spacingSm * 2
    radius: Theme.radiusMd
    color: Theme.panelBackground
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    Text {
        id: hint
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        color: Theme.foreground
        text: hintBox.message
    }
}
