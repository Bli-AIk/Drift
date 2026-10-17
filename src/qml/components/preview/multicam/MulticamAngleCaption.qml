import QtQuick
import Drift

Text {
    id: caption

    required property string name

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Theme.spacingSm
    text: caption.name
    elide: Text.ElideMiddle
    color: "#ffffff"
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs
    style: Text.Outline
    styleColor: Theme.overlayColor
}
