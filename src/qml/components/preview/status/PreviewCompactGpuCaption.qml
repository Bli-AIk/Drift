import QtQuick
import Drift

Text {
    anchors.centerIn: parent
    width: parent.width - Theme.spacingXl
    text: qsTr("GPU preview unavailable")
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
    color: Theme.guideMedium
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSm
}
