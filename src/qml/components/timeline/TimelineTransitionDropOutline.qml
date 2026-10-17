import QtQuick
import Drift

// Where a dragged transition would land.
Rectangle {
    property TimelinePanel panel
    property int trackIndex: -1
    visible: panel.transitionDropTrackIndex === trackIndex
    x: panel.transitionDropStart * panel.pxPerSecond
    width: Math.max(8, (panel.transitionDropEnd - panel.transitionDropStart) * panel.pxPerSecond)
    height: parent.height
    radius: Theme.radiusSm
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
    border.width: 2
    border.color: Theme.transitionOverlap
    z: 11
}
