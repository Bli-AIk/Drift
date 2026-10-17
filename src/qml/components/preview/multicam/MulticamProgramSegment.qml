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
    radius: Theme.radiusSm
    color: Theme.panelSecondaryBg
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    Text {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - Theme.spacingSm
        text: segment.modelData.name
        elide: Text.ElideRight
        color: Theme.panelForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
