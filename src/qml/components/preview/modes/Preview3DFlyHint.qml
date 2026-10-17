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
    radius: Theme.c.preview3DFlyHint.radius
    color: Theme.c.preview3DFlyHint.background
    border.width: Theme.c.preview3DFlyHint.borderWidth
    border.color: Theme.c.preview3DFlyHint.border

    Text {
        id: hint
        anchors.centerIn: parent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        color: Theme.c.preview3DFlyHint.foreground
        text: hintBox.message
    }
}
