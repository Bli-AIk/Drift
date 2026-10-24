import QtQuick
import Drift

Canvas {
    property var host
    property real viewportWidth: 0
    id: root
    readonly property color beatBarColor: Theme.c.keyframeGraphBeatCanvas.beatBar
    readonly property color beatGridColor: Theme.c.keyframeGraphBeatCanvas.beatGrid
    readonly property color beatOnsetColor: Theme.c.keyframeGraphBeatCanvas.beatOnset
    readonly property real beatBarWidth: Theme.c.keyframeGraphBeatCanvas.beatBarWidth
    readonly property real beatGridWidth: Theme.c.keyframeGraphBeatCanvas.beatGridWidth
    onBeatBarColorChanged: requestPaint()
    onBeatGridColorChanged: requestPaint()
    onBeatOnsetColorChanged: requestPaint()
    onBeatBarWidthChanged: requestPaint()
    onBeatGridWidthChanged: requestPaint()
    // Viewport-sized, not content-sized — see curveCanvas.
    x: host.paintOriginX
    width: viewportWidth + 2 * host.paintChunk
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    z: 0
    visible: host.hasGrid || host.hasOnsets

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const a = host.beats
        if (!a)
            return
        // Canvas-local x for an absolute timeline position. Rounding happens
        // after the shift, so a fractional scroll offset cannot push a 1px
        // tick onto a half-pixel and smear it across two columns.
        const localX = t => Math.round(host.xForSeconds(t) - host.paintOriginX)

        const t0 = host.secondsForX(host.paintOriginX - 3)
        const t1 = host.secondsForX(host.paintOriginX + width + 3)

        if (host.hasGrid) {
            const perBar = a.beatsPerBar || 4
            const first = a.firstDownbeat || 0
            for (let i = Math.max(0, host.lowerBound(a.beats, t0) - 1); i < a.beats.length; ++i) {
                if (a.beats[i] > t1)
                    break
                const isBar = ((i - first) % perBar + perBar) % perBar === 0
                const px = localX(a.beats[i])
                if (px < -2 || px > width + 2)
                    continue
                ctx.fillStyle = String(isBar ? root.beatBarColor
                                             : root.beatGridColor)
                ctx.fillRect(px, 0, isBar ? root.beatBarWidth : root.beatGridWidth, height)
            }
        }

        if (!host.hasOnsets)
            return

        // With the grid up, only transients that miss it — the rest would
        // just double-draw lines already there. Height tracks strength.
        ctx.fillStyle = String(root.beatOnsetColor)
        const onsets = a.onsets || []
        for (let j = Math.max(0, host.lowerBound(onsets, t0, "seconds") - 1); j < onsets.length; ++j) {
            if (onsets[j].seconds > t1)
                break
            if (host.hasGrid && onsets[j].nearBeat)
                continue
            const ox = localX(onsets[j].seconds)
            if (ox < -2 || ox > width + 2)
                continue
            // Centered rather than sitting on the floor: a 1px tick down
            // at the bottom edge read as chart furniture next to the
            // full-height beat lines.
            const h = Math.max(6, onsets[j].strength * height * 0.5)
            ctx.fillRect(ox - 1, (height - h) / 2, 2, h)
        }
    }

    // The canvas is hidden until the first analysis lands, and a
    // requestPaint issued while hidden is dropped.
    onVisibleChanged: if (visible) requestPaint()

    Connections {
        target: host
        function onBeatsChanged() { root.requestPaint() }
        // Toggling a layer leaves beatAnalysis itself untouched, so
        // onBeatsChanged does not fire for it.
        function onHasGridChanged() { root.requestPaint() }
        function onHasOnsetsChanged() { root.requestPaint() }
        function onPxPerSecondChanged() { root.requestPaint() }
        function onPaintOriginXChanged() { root.requestPaint() }
    }
}
