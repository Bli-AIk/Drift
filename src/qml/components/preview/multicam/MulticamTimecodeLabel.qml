import QtQuick
import Drift

Text {
    id: label

    required property string textValue

    anchors.verticalCenter: parent.verticalCenter
    text: label.textValue
    color: Theme.panelForeground
    font.family: Theme.monoFontFamily
    font.pixelSize: Theme.fontSizeSm
}
