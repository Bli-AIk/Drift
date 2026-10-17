import QtQuick
import Drift

// Spot direction: a line from the light to where it is aimed.
Rectangle {
    id: line

    required property var source
    required property var frame

    visible: line.source.isLight && line.source.values.spot
    readonly property real dx: (line.source.ax - line.source.hx) * line.frame.width
    readonly property real dy: (line.source.ay - line.source.hy) * line.frame.height
    x: line.source.hx * line.frame.width
    y: line.source.hy * line.frame.height - height / 2
    width: Math.sqrt(dx * dx + dy * dy)
    height: Theme.c.depthEffectAimLine.strokeWidth
    color: line.source.values.color || Theme.c.depthEffectAimLine.background
    opacity: Theme.c.depthEffectAimLine.opacity
    transformOrigin: Item.Left
    rotation: Math.atan2(dy, dx) * 180 / Math.PI
}
