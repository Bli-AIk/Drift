import QtQuick
import Drift

// Short mark in the middle of a transition region.
Text {
    property bool hasTransition: false
    property string labelText: ""
    anchors.centerIn: parent
    visible: parent.width >= 28
    text: hasTransition && labelText ? labelText.charAt(0) : "≫"
    color: Theme.onMedia
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeTiny
    font.weight: Font.Bold
}
