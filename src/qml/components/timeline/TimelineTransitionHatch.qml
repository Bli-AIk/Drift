import QtQuick
import Drift

// Diagonal hatch so a transition overlap reads as a blend zone.
Canvas {
    anchors.fill: parent
    anchors.margins: 1
    opacity: 0.35
    readonly property color hatch: Theme.c.timelineTransitionHatch.foreground
    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        ctx.strokeStyle = hatch
        ctx.lineWidth = Theme.c.timelineTransitionHatch.borderWidth
        const step = 6
        for (let x = -height; x < width; x += step) {
            ctx.beginPath()
            ctx.moveTo(x, height)
            ctx.lineTo(x + height, 0)
            ctx.stroke()
        }
    }
    onHatchChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
