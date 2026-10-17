import QtQuick
import Drift

// Bottom edge so the seek strip reads as a distinct bar.
Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 1
    color: Theme.c.timelineSeekStripEdge.border
}
