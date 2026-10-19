import QtQuick
import Drift

Canvas {
    property var host
    id: root
    readonly property color curveColor: Theme.c.speedCurveCanvas.curve
    readonly property color handleColor: Theme.c.speedCurveCanvas.handle
    readonly property real curveLineWidth: Theme.c.speedCurveCanvas.curveLineWidth
    readonly property real handleLineWidth: Theme.c.speedCurveCanvas.handleLineWidth
    onCurveColorChanged: requestPaint()
    onHandleColorChanged: requestPaint()
    onCurveLineWidthChanged: requestPaint()
    onHandleLineWidthChanged: requestPaint()
    anchors.fill: parent

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const pts = host.points
        if (pts.length < 2)
            return

        ctx.strokeStyle = String(root.curveColor)
        ctx.lineWidth = root.curveLineWidth
        ctx.beginPath()
        ctx.moveTo(pts[0].pos * width, host.yForSpeed(pts[0].speed, height))
        for (let i = 0; i + 1 < pts.length; ++i) {
            const a = pts[i]
            const b = pts[i + 1]
            ctx.bezierCurveTo(
                (a.pos + a.outDx) * width, host.yForSpeed(a.speed + a.outDy, height),
                (b.pos + b.inDx) * width, host.yForSpeed(b.speed + b.inDy, height),
                b.pos * width, host.yForSpeed(b.speed, height))
        }
        ctx.stroke()

        // Tangents, for the selected point only — drawing every handle turns the
        // graph into a thicket.
        const sel = host.selected
        if (sel) {
            ctx.strokeStyle = String(root.handleColor)
            ctx.lineWidth = root.handleLineWidth
            const px = sel.pos * width
            const py = host.yForSpeed(sel.speed, height)
            ctx.beginPath()
            ctx.moveTo((sel.pos + sel.inDx) * width,
                       host.yForSpeed(sel.speed + sel.inDy, height))
            ctx.lineTo(px, py)
            ctx.lineTo((sel.pos + sel.outDx) * width,
                       host.yForSpeed(sel.speed + sel.outDy, height))
            ctx.stroke()
        }
    }

    Connections {
        target: host
        function onPointsChanged() { root.requestPaint() }
        function onSelectedPointChanged() { root.requestPaint() }
    }
}
