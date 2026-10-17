import QtQuick
import Drift

Canvas {
    property var host
    property real inset: 0
    id: root
    anchors.fill: parent
    anchors.margins: inset
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width
        const h = height
        if (w < 2 || h < 2)
            return

        ctx.strokeStyle = String(Theme.panelBorder)
        ctx.lineWidth = 1
        ctx.globalAlpha = 0.45
        for (let i = 1; i < 4; ++i) {
            const y = h * i / 4
            ctx.beginPath()
            ctx.moveTo(0, y)
            ctx.lineTo(w, y)
            ctx.stroke()
            const x = w * i / 4
            ctx.beginPath()
            ctx.moveTo(x, 0)
            ctx.lineTo(x, h)
            ctx.stroke()
        }
        ctx.globalAlpha = 1

        if (host.isBezier) {
            const hd = host.handles
            const x1 = hd[0] * w, y1 = h * (1.0 - hd[1])
            const x2 = hd[2] * w, y2 = h * (1.0 - hd[3])

            const bfill = Theme.primary
            ctx.fillStyle = Qt.rgba(bfill.r, bfill.g, bfill.b, 0.18)
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.lineTo(0, h)
            ctx.bezierCurveTo(x1, y1, x2, y2, w, 0)
            ctx.lineTo(w, h)
            ctx.closePath()
            ctx.fill()

            // Handle arms first, so the curve reads on top of them.
            ctx.strokeStyle = String(Theme.mutedForeground)
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.lineTo(x1, y1)
            ctx.moveTo(w, 0)
            ctx.lineTo(x2, y2)
            ctx.stroke()

            ctx.strokeStyle = String(Theme.primary)
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.bezierCurveTo(x1, y1, x2, y2, w, 0)
            ctx.stroke()
            return
        }

        const pts = host.points
        if (!pts || pts.length < 2)
            return

        const fill = Theme.primary
        ctx.fillStyle = Qt.rgba(fill.r, fill.g, fill.b, 0.18)
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (let i = 0; i < pts.length; ++i)
            ctx.lineTo(pts[i].t * w, h * (1.0 - pts[i].g))
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fill()

        ctx.strokeStyle = String(Theme.primary)
        ctx.lineWidth = 2
        ctx.beginPath()
        for (let i = 0; i < pts.length; ++i) {
            const x = pts[i].t * w
            const y = h * (1.0 - pts[i].g)
            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }
        ctx.stroke()
    }

    Connections {
        target: host
        function onPointsChanged() { root.requestPaint() }
        function onSelectedPointChanged() { root.requestPaint() }
        function onHandlesChanged() { root.requestPaint() }
        function onShapeModeChanged() { root.requestPaint() }
        function onSelectedHandleChanged() { root.requestPaint() }
    }
}
