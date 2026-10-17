import QtQuick
import Drift

Rectangle {
    required property string section
    property real rowWidth: 0
    width: rowWidth
    height: 24
    color: Theme.c.fontPickerSectionHeader.backgroundSecondary

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: section
        color: Theme.c.fontPickerSectionHeader.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
