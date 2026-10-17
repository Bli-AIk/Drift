import QtQuick
import Drift

// "%n track(s)" beside the foot while a transform span is dragged.
Rectangle {
    property bool shown: false
    property real lineX: 0
    property real indentStep: 8
    property real bottomY: 0
    property int snapCount: 0
    visible: shown
    x: lineX + indentStep + 4
    y: bottomY - height / 2
    width: chipLabel.implicitWidth + Theme.spacingMd * 2
    height: chipLabel.implicitHeight + Theme.spacingXs * 2
    radius: height / 2
    color: Theme.clipTransform
    z: 5

    Text {
        id: chipLabel
        anchors.centerIn: parent
        text: qsTr("%n track(s)", "", snapCount)
        color: Theme.onMedia
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeTiny
    }
}
