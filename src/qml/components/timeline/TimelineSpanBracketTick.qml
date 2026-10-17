import QtQuick
import Drift

// Tick at the top of a transform-span bracket.
Rectangle {
    property real lineX: 0
    property real topY: 0
    property real indentStep: 8
    x: lineX
    y: topY - 1
    width: indentStep - 2
    height: 2
    radius: 1
    color: Theme.clipTransform
}
