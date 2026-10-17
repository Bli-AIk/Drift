import QtQuick
import Drift

// Outline of the kept range on the filmstrip.
Rectangle {
    id: span

    required property real inX
    required property real outX

    x: span.inX
    width: Math.max(2, span.outX - span.inX)
    height: parent.height
    color: "transparent"
    border.width: Theme.borderWidth
    border.color: Theme.primary
}
