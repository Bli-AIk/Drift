import QtQuick
import Drift

// Short "V1" / custom name in the compact header, between the grip and the toggles.
Text {
    property string label: ""
    property real centerOffset: 0
    property Item iconRow
    anchors.left: parent.left
    anchors.leftMargin: 18
    anchors.right: iconRow.left
    anchors.rightMargin: Theme.spacingSm
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: centerOffset
    text: label
    color: Theme.mutedForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeTiny
    elide: Text.ElideRight
}
