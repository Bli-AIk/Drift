import QtQuick

// One guide: a line, a margin rect, or a centred aspect frame.
Rectangle {
    id: mark

    required property var modelData
    required property real canvasWidth
    required property real canvasHeight

    readonly property string kind: modelData.kind
    readonly property bool outline: kind === "rect" || kind === "aspect"
    // Largest frame of the item's aspect that fits the canvas, centred.
    readonly property real frameW: Math.min(mark.canvasWidth, mark.canvasHeight * modelData.aspect)
    readonly property real frameH: Math.min(mark.canvasHeight, mark.canvasWidth / modelData.aspect)

    x: kind === "v" ? mark.canvasWidth * modelData.pos
       : kind === "rect" ? mark.canvasWidth * modelData.left
       : kind === "aspect" ? (mark.canvasWidth - frameW) / 2 : 0
    y: kind === "h" ? mark.canvasHeight * modelData.pos
       : kind === "rect" ? mark.canvasHeight * modelData.top
       : kind === "aspect" ? (mark.canvasHeight - frameH) / 2 : 0
    width: kind === "v" ? 1
           : kind === "rect" ? mark.canvasWidth * (1 - modelData.left - modelData.right)
           : kind === "aspect" ? frameW : mark.canvasWidth
    height: kind === "h" ? 1
            : kind === "rect" ? mark.canvasHeight * (1 - modelData.top - modelData.bottom)
            : kind === "aspect" ? frameH : mark.canvasHeight
    color: outline ? "transparent" : modelData.color
    border.width: outline ? Theme.c.guideLayerMark.borderWidth : 0
    border.color: modelData.color
    opacity: modelData.opacity
}
