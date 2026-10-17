import QtQuick
import Drift

// Blinking record dot. Holds amber while the take is paused.
Rectangle {
    property bool paused: false
    property bool running: false
    width: 8
    height: 8
    radius: 4
    color: paused ? "#eab308" : Theme.destructive
    anchors.verticalCenter: parent.verticalCenter

    SequentialAnimation on opacity {
        running: running && !paused
        loops: Animation.Infinite
        NumberAnimation { to: 0.2; duration: 400 }
        NumberAnimation { to: 1.0; duration: 400 }
    }
}
