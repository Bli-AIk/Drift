import QtQuick
import Drift

// Playhead handle: a small flag at the top of the line that continues down
// through the strip below, matching the timeline's playhead silhouette.
Item {
    id: cap

    required property real playX

    x: cap.playX - width / 2
    y: 6
    width: 10
    height: 10

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Theme.primary
    }
}
