import QtQuick
import Drift

// Foot of a transform-span bracket. Grows while the pointer is on it.
Rectangle {
    property real lineX: 0
    property real drawnBottom: 0
    property real indentStep: 8
    property bool hot: false
    x: lineX
    y: drawnBottom - 1
    width: indentStep - 2
    height: 2
    radius: 1
    color: Theme.clipTransform
    scale: hot ? 1.4 : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
}
