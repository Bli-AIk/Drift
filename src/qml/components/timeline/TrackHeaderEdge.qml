import QtQuick
import Drift

// Right border of one track header, only as tall as the row itself.
Rectangle {
    property TrackHeaderColumn column
    property int trackIndex: -1
    anchors.right: parent.right
    width: 1
    height: column.trackHeight(trackIndex)
    color: Theme.c.trackHeaderEdge.border
}
