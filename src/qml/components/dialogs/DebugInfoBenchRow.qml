import QtQuick
import Drift

Item {
    id: benchRow
    required property string label
    required property string value
    property bool emphasis: false
    width: parent ? parent.width : 0
    height: Math.max(Theme.controlHeightSm, benchValue.implicitHeight + Theme.spacingSm)

    ThemedLabel {
        width: Math.round(benchRow.width * 0.5)
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: Theme.spacingLg
        size: "xs"
        text: benchRow.label
    }
    ThemedLabel {
        id: benchValue
        x: Math.round(benchRow.width * 0.5)
        width: benchRow.width - x
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: Theme.spacingLg
        size: "xs"
        tone: "default"
        font.weight: benchRow.emphasis ? Font.Medium : Font.Normal
        wrapMode: Text.WordWrap
        text: benchRow.value
    }
}
