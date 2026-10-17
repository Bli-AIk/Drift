import QtQuick
import Drift

// Window marking the slice of the project the zoomed view is showing.
Rectangle {
    property real spanX: 0
    property real spanWidth: 0
    x: spanX
    width: Math.max(3, spanWidth)
    y: 1
    height: parent.height - 3
    radius: 2
    color: "transparent"
    border.width: 1
    border.color: Theme.primary
}
