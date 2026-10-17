import QtQuick
import Drift

// Clip span backdrop behind the subtitle cues.
Rectangle {
    property SubtitleCueLane lane
    x: lane.xForSeconds(0)
    width: Math.max(2, lane.clipDuration * lane.pxPerSecond)
    height: parent.height
    color: Theme.panelAccent
    opacity: 0.4
}
