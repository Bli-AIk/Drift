import QtQuick
import Drift

// Pointed tip so the head reads as a scrubber, not a knob.
Canvas {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: parent.height * 0.4
    width: parent.width
    height: parent.height * 0.6
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.lineTo(width, 0)
        ctx.lineTo(width * 0.5, height)
        ctx.closePath()
        ctx.fillStyle = Theme.primary
        ctx.fill()
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
