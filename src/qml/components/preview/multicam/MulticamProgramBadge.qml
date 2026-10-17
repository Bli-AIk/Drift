import QtQuick
import Drift

Text {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: Theme.spacingSm
    text: qsTr("Program")
    color: Theme.c.multicamProgramBadge.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs
    style: Text.Outline
    styleColor: Theme.c.multicamProgramBadge.shadow
}
