import QtQuick
import Drift

// Blinking record dot. Holds amber while the take is paused.
Rectangle {
    property bool paused: false
    property bool running: false
    width: 8
    height: 8
    radius: Theme.c.voiceoverRecDot.radius
    color: paused ? Theme.c.voiceoverRecDot.paused : Theme.c.voiceoverRecDot.recording
    anchors.verticalCenter: parent.verticalCenter

    SequentialAnimation on opacity {
        running: running && !paused
        loops: Animation.Infinite
        NumberAnimation { to: 0.2; duration: 400 }
        NumberAnimation { to: 1.0; duration: 400 }
    }
}
