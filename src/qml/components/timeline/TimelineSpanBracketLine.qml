import QtQuick
import Drift

// Solid stem of a transform-span bracket.
Rectangle {
    property bool shown: true
    property real lineX: 0
    property real topY: 0
    property real drawnBottom: 0
    visible: shown
    x: lineX
    y: topY
    width: 2
    height: Math.max(0, drawnBottom - topY)
    radius: 1
    color: Theme.clipTransform
}
