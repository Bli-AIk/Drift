import QtQuick
import Drift

Canvas {
    property var host
    id: root
    anchors.fill: parent

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const pts = host.points
        if (pts.length < 2)
            return

        ctx.strokeStyle = String(Theme.primary)
        ctx.lineWidth = 2
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
            ctx.strokeStyle = String(Theme.mutedForeground)
            ctx.lineWidth = 1
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
