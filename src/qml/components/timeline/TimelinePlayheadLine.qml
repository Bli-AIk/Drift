import QtQuick
import Drift

// The playhead needle below the scrubber head.
Rectangle {
    anchors.left: parent.left
    y: Theme.timelineRulerHeight * 0.55
    width: Theme.playheadLineWidth
    height: parent.height - y
    color: Theme.primary
}
