import QtQuick
import Drift
import "../keyframes/EasingCache.js" as EasingCache

Canvas {
    property var host
    property real viewportWidth: 0
    id: root
    readonly property real lineWidth: Theme.c.keyframeGraphCurveCanvas.lineWidth
    readonly property real lineWidthMuted: Theme.c.keyframeGraphCurveCanvas.lineWidthMuted
    readonly property real opacityContext: Theme.c.keyframeGraphCurveCanvas.opacityContext
    readonly property real opacityDisabled: Theme.c.keyframeGraphCurveCanvas.opacityDisabled
    onLineWidthChanged: requestPaint()
    onLineWidthMutedChanged: requestPaint()
    onOpacityContextChanged: requestPaint()
    onOpacityDisabledChanged: requestPaint()
    // Only as wide as the visible strip, parked at the viewport's left edge
    // (content is offset by -contentX, so x: contentX cancels the scroll).
    // Filling the scrollable content instead would size the backing texture
    // to the whole timeline, and QSGPlainTexture silently rescales anything
    // past GL_MAX_TEXTURE_SIZE to fit — 16384px, which at 40x zoom is barely
    // 8 seconds of timeline. Past that the curves are drawn correctly and
    // then downsampled onto the GPU, which is what smeared them.
    x: host.paintOriginX
    width: viewportWidth + 2 * host.paintChunk
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        // Everything below is in absolute timeline coordinates.
        ctx.save()
        ctx.translate(-host.paintOriginX, 0)
        const spanX0 = host.xForSeconds(host.clipStart)
        const spanX1 = host.xForSeconds(host.clipStart + host.clipDuration)

        for (let s = 0; s < host.series.length; ++s) {
            const entry = host.series[s]
            const isLinkedPartner = EditorState.positionLinked
                && ((host.dragProp === "x" && entry.prop === "y") || (host.dragProp === "y" && entry.prop === "x"))

            const affected = entry.prop === host.dragProp || isLinkedPartner
            const live = !affected ? null : entry.points.map(function (p, i) {
                if (entry.prop === host.dragProp) {
                    if (i === host.dragTangentIndex) {
                        // Handle being dragged: same key, reshaped.
                        return {
                            seconds: p.seconds, value: p.value, hold: p.hold, fn: p.fn, fnAmp: p.fnAmp, fnPeriod: p.fnPeriod,
                            inDx: host.dragTangentInDx, inDy: host.dragTangentInDy,
                            outDx: host.dragTangentOutDx, outDy: host.dragTangentOutDy
                        }
                    }
                    if (i === host.dragIndex) {
                        // Key being moved: carry its tangents through, so the
                        // curve shape does not snap back to linear mid-drag.
                        return {
                            seconds: host.dragSeconds, value: host.dragValue,
                            inDx: p.inDx, inDy: p.inDy,
                            outDx: p.outDx, outDy: p.outDy, hold: p.hold, fn: p.fn, fnAmp: p.fnAmp, fnPeriod: p.fnPeriod
                        }
                    }
                } else if (isLinkedPartner) {
                    if (host.dragTangentIndex >= 0 && host.focusedIndex >= 0 && host.focusedIndex < host.series.length) {
                        const masterPts = host.series[host.focusedIndex].points
                        const masterP = masterPts ? masterPts[host.dragTangentIndex] : null
                        if (masterP && Math.abs(masterP.seconds - p.seconds) < (1 / 30)) {
                            let partnerInDy = 0.0
                            let partnerOutDy = 0.0
                            if (i + 1 < entry.points.length && host.dragTangentIndex + 1 < masterPts.length) {
                                const mSpan = masterPts[host.dragTangentIndex + 1].value - masterP.value
                                const sSpan = entry.points[i + 1].value - p.value
                                if (Math.abs(mSpan) > 1e-6)
                                    partnerOutDy = host.dragTangentOutDy * (sSpan / mSpan)
                            }
                            if (i > 0 && host.dragTangentIndex > 0) {
                                const mSpan = masterP.value - masterPts[host.dragTangentIndex - 1].value
                                const sSpan = p.value - entry.points[i - 1].value
                                if (Math.abs(mSpan) > 1e-6)
                                    partnerInDy = host.dragTangentInDy * (sSpan / mSpan)
                            }
                            return {
                                seconds: p.seconds, value: p.value, hold: p.hold, fn: p.fn, fnAmp: p.fnAmp, fnPeriod: p.fnPeriod,
                                inDx: host.dragTangentInDx, inDy: partnerInDy,
                                outDx: host.dragTangentOutDx, outDy: partnerOutDy
                            }
                        }
                    } else if (host.dragIndex >= 0 && host.focusedIndex >= 0 && host.focusedIndex < host.series.length) {
                        const masterPts = host.series[host.focusedIndex].points
                        const masterP = masterPts ? masterPts[host.dragIndex] : null
                        if (masterP && Math.abs(masterP.seconds - p.seconds) < (1 / 30)) {
                            return {
                                seconds: host.dragSeconds, value: p.value,
                                inDx: p.inDx, inDy: p.inDy,
                                outDx: p.outDx, outDy: p.outDy, hold: p.hold, fn: p.fn, fnAmp: p.fnAmp, fnPeriod: p.fnPeriod
                            }
                        }
                    }
                }
                return p
            })
            const sorted = affected ? live.sort((a, b) => a.seconds - b.seconds) : EasingCache.sortedPoints(entry)

            // The focused series is the one being edited; the rest are
            // context and are drawn thinner and faded. A series whose
            // keyframes are switched off is faded further still — its curve
            // is a record of an animation that is not currently playing.
            const focused = host.isFocused(s)
            // Whole pixels. A 1.8px stroke lands ~40/100/40% across three
            // rows, which reads as a glow wherever the curve runs shallow —
            // exactly the flat tops and troughs between keys.
            ctx.lineWidth = focused ? root.lineWidth : root.lineWidthMuted
            ctx.globalAlpha = (host.curveEditing && !focused) ? root.opacityContext : 1.0
            if (entry.enabled === false)
                ctx.globalAlpha *= root.opacityDisabled
            ctx.strokeStyle = String(entry.color)
            ctx.beginPath()

            // An unkeyed property is a flat line at the value it actually
            // holds, so every selected property reads as an editable curve
            // spanning the clip rather than as nothing at all.
            if (sorted.length === 0) {
                const by = host.yForValue(entry.baseValue, entry)
                ctx.moveTo(spanX0, by)
                ctx.lineTo(spanX1, by)
                ctx.stroke()
                continue
            }

            // Outside the keyed range the value is held flat, which is what
            // evaluateAt does — so the drawn line matches playback.
            const leadY = host.yForValue(sorted[0].value, entry)
            ctx.moveTo(spanX0, leadY)
            ctx.lineTo(host.xForSeconds(sorted[0].seconds), leadY)
            for (let i = 1; i < sorted.length; ++i) {
                const a = sorted[i - 1]
                const b = sorted[i]
                const ax = host.xForSeconds(a.seconds)
                const ay = host.yForValue(a.value, entry)
                const bx = host.xForSeconds(b.seconds)
                const by = host.yForValue(b.value, entry)

                if (a.hold) {
                    // Step: hold the outgoing value, then jump.
                    ctx.lineTo(bx, ay)
                    ctx.lineTo(bx, by)
                    continue
                }
                if (a.fn) {
                    // A Penner function ignores the handles; the engine's samples are the curve.
                    const samples = EasingCache.samples(host.easingFnSpec(a), 48, (s, n) => EditorState.easingSamples(s, n))
                    for (let k = 0; k < samples.length; ++k) {
                        const u = samples[k].x
                        const f = samples[k].y
                        ctx.lineTo(ax + (bx - ax) * u, host.yForValue(a.value + (b.value - a.value) * f, entry))
                    }
                    continue
                }
                // Handles are clamped into the segment exactly as the
                // evaluator does, so the drawn curve matches playback.
                const c1x = Math.min(bx, Math.max(ax, ax + host.xForSeconds(a.outDx || 0)))
                const c2x = Math.min(bx, Math.max(ax, bx + host.xForSeconds(b.inDx || 0)))
                const c1y = host.yForValue(a.value + (a.outDy || 0), entry)
                const c2y = host.yForValue(b.value + (b.inDy || 0), entry)
                ctx.bezierCurveTo(c1x, c1y, c2x, c2y, bx, by)
            }
            const tail = sorted[sorted.length - 1]
            ctx.lineTo(spanX1, host.yForValue(tail.value, entry))
            ctx.stroke()
        }
        ctx.globalAlpha = 1.0
        ctx.restore()
    }
    Connections {
        target: host
        function onSeriesChanged() { root.requestPaint() }
        function onPxPerSecondChanged() { root.requestPaint() }
        function onPaintOriginXChanged() { root.requestPaint() }
        function onDragSecondsChanged() { root.requestPaint() }
        function onDragValueChanged() { root.requestPaint() }
        function onDragTangentOutDyChanged() { root.requestPaint() }
        function onDragTangentOutDxChanged() { root.requestPaint() }
        function onDragTangentInDyChanged() { root.requestPaint() }
        function onDragTangentInDxChanged() { root.requestPaint() }
        function onFocusedPropChanged() { root.requestPaint() }
        function onLaneHeightChanged() { root.requestPaint() }
    }
}
