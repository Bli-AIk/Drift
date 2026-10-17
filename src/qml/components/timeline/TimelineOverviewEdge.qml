import QtQuick
import Drift

// Bottom hairline of the timeline minimap.
Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Theme.c.timelineOverviewEdge.border
}
