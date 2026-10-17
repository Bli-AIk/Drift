import QtQuick
import Drift

Canvas {
    property var host
    property real inset: 0
    id: root
    readonly property color gridColor: Theme.c.fadeCurveCanvas.grid
    readonly property color fillColor: Theme.c.fadeCurveCanvas.fill
    readonly property color curveColor: Theme.c.fadeCurveCanvas.curve
    readonly property color handleColor: Theme.c.fadeCurveCanvas.handle
    readonly property real gridOpacity: Theme.c.fadeCurveCanvas.gridOpacity
    readonly property real fillOpacity: Theme.c.fadeCurveCanvas.fillOpacity
    readonly property real gridLineWidth: Theme.c.fadeCurveCanvas.gridLineWidth
    readonly property real handleLineWidth: Theme.c.fadeCurveCanvas.handleLineWidth
    readonly property real curveLineWidth: Theme.c.fadeCurveCanvas.curveLineWidth
    onGridColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onCurveColorChanged: requestPaint()
    onHandleColorChanged: requestPaint()
    onGridOpacityChanged: requestPaint()
    onFillOpacityChanged: requestPaint()
    onGridLineWidthChanged: requestPaint()
    onHandleLineWidthChanged: requestPaint()
    onCurveLineWidthChanged: requestPaint()
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

        ctx.strokeStyle = String(root.gridColor)
        ctx.lineWidth = root.gridLineWidth
        ctx.globalAlpha = root.gridOpacity
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

            const bfill = root.fillColor
            ctx.fillStyle = Qt.rgba(bfill.r, bfill.g, bfill.b, root.fillOpacity)
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.lineTo(0, h)
            ctx.bezierCurveTo(x1, y1, x2, y2, w, 0)
            ctx.lineTo(w, h)
            ctx.closePath()
            ctx.fill()

            // Handle arms first, so the curve reads on top of them.
            ctx.strokeStyle = String(root.handleColor)
            ctx.lineWidth = root.handleLineWidth
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.lineTo(x1, y1)
            ctx.moveTo(w, 0)
            ctx.lineTo(x2, y2)
            ctx.stroke()

            ctx.strokeStyle = String(root.curveColor)
            ctx.lineWidth = root.curveLineWidth
            ctx.beginPath()
            ctx.moveTo(0, h)
            ctx.bezierCurveTo(x1, y1, x2, y2, w, 0)
            ctx.stroke()
            return
        }

        const pts = host.points
        if (!pts || pts.length < 2)
            return

        const fill = root.fillColor
        ctx.fillStyle = Qt.rgba(fill.r, fill.g, fill.b, root.fillOpacity)
        ctx.beginPath()
        ctx.moveTo(0, h)
        for (let i = 0; i < pts.length; ++i)
            ctx.lineTo(pts[i].t * w, h * (1.0 - pts[i].g))
        ctx.lineTo(w, h)
        ctx.closePath()
        ctx.fill()

        ctx.strokeStyle = String(root.curveColor)
        ctx.lineWidth = root.curveLineWidth
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
