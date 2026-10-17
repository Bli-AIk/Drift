import QtQuick
import Drift

// The mask outline. Ellipse and the ornamental shapes are drawn as their bounding
// box plus a hint, rather than reproducing the rasterizer's geometry in QML — the
// point of the box is the handles, and the real shape is visible in the composite
// behind it.
Rectangle {
    id: outline

    required property bool selected
    required property bool enabledMask
    required property string shape

    anchors.fill: parent
    color: "transparent"
    border.width: Theme.borderWidth
    border.color: outline.selected ? Theme.primary : Theme.mutedForeground
    opacity: !outline.enabledMask ? 0.25 : (outline.selected ? 1.0 : 0.5)
    radius: outline.shape === "ellipse" ? Math.min(width, height) / 2 : 0
}
