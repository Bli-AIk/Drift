import QtQuick
import Drift

// Body of the ghost lane a drop would insert.
Rectangle {
    anchors.fill: parent
    radius: Theme.c.timelineNewTrackGhostLane.radius
    color: Qt.rgba(Theme.c.timelineNewTrackGhostLane.background.r, Theme.c.timelineNewTrackGhostLane.background.g, Theme.c.timelineNewTrackGhostLane.background.b, 0.92)
    border.width: Theme.c.timelineNewTrackGhostLane.borderWidth
    border.color: Theme.c.timelineNewTrackGhostLane.border
}
