import QtQuick
import Drift

// Tint and bottom hairline of one nested adjustment lane.
Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.c.timelineAdjustmentLaneChrome.background.r, Theme.c.timelineAdjustmentLaneChrome.background.g, Theme.c.timelineAdjustmentLaneChrome.background.b, 0.12)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.c.timelineAdjustmentLaneChrome.edge
    }
}
