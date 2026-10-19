import QtQuick
import Drift

// Faint wash on a transform layer's row.
Rectangle {
    property TimelinePanel panel
    property int trackIndex: -1
    anchors.fill: parent
    visible: panel.tracks[trackIndex].isTransformLayer === true
    color: Qt.rgba(Theme.c.timelineTrackTransformWash.background.r, Theme.c.timelineTrackTransformWash.background.g, Theme.c.timelineTrackTransformWash.background.b, 0.07)
}
