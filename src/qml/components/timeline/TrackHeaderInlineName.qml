import QtQuick
import Drift

// Name on a short header, between the grip and the toggles.
Text {
    property string label: ""
    property real centerOffset: 0
    property Item iconRow
    anchors.left: parent.left
    anchors.leftMargin: Theme.spacing3xl + Theme.spacingSm
    anchors.right: iconRow.left
    anchors.rightMargin: Theme.spacingSm
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: centerOffset
    text: label
    color: Theme.c.trackHeaderInlineName.foregroundMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeTiny
    elide: Text.ElideRight
}
