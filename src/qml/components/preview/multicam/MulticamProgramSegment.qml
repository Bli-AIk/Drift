import QtQuick
import Drift

// One staged program clip on the lane.
Rectangle {
    id: segment

    required property var modelData
    required property real laneWidth
    required property real laneHeight
    required property real span

    x: segment.laneWidth * (modelData.start / segment.span)
    width: Math.max(1, segment.laneWidth * (modelData.duration / segment.span))
    height: segment.laneHeight
    radius: Theme.c.multicamProgramSegment.radius
    color: Theme.c.multicamProgramSegment.background
    border.width: Theme.c.multicamProgramSegment.borderWidth
    border.color: Theme.c.multicamProgramSegment.border

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Theme.spacingSm
        text: segment.modelData.name
        elide: Text.ElideRight
        color: Theme.c.multicamProgramSegment.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
