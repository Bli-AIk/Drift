import QtQuick
import Drift

Canvas {
    id: root

    required property var panel
    required property real viewWidth

    readonly property var timeView: panel.timeView
    readonly property real paintChunk: 256
    readonly property real paintOriginX: Math.floor(timeView.contentX / paintChunk) * paintChunk - paintChunk
    readonly property real rangeX0: panel.mediaRange.start * timeView.pxPerSecond
    readonly property real rangeX1: (panel.mediaRange.start + panel.mediaRange.duration) * timeView.pxPerSecond
    readonly property real windowX0: Math.max(rangeX0, paintOriginX)
    readonly property real windowX1: Math.min(rangeX1, paintOriginX + viewWidth + 2 * paintChunk)
    readonly property real waveStart: windowX0 / timeView.pxPerSecond
    readonly property real waveDuration: Math.max(0, windowX1 - windowX0) / timeView.pxPerSecond
    readonly property int peakCount: {
        const w = Math.max(1, Math.ceil(width))
        return Math.min(8192, Math.max(64, Math.ceil(w / 64) * 64))
    }
    readonly property color wave: Theme.c.subtitleLane.waveform
    property int waveformRevision: 0
    property var peaks: {
        void EditorState.tracksRevision
        void waveformRevision
        return (visible && waveDuration > 0)
            ? EditorState.subtitleWaveformColumns(waveStart, waveDuration, peakCount,
                                                  Math.max(1, Math.floor(width)))
            : []
    }

    x: windowX0 - timeView.contentX
    width: Math.max(2, windowX1 - windowX0)
    visible: panel.mediaRange.duration > 0 && windowX1 > windowX0
    opacity: Theme.c.subtitleLane.opacityWaveform

    onWaveChanged: requestPaint()
    onPeaksChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    Connections {
        target: EditorState

        function onSubtitleWaveformReady(s, d, n) {
            if (Math.abs(s - root.waveStart) < 1e-6 && Math.abs(d - root.waveDuration) < 1e-6
                    && n === root.peakCount)
                root.waveformRevision++
        }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (!peaks || peaks.length === 0)
            return
        ctx.fillStyle = wave
        const mid = height / 2
        for (let x = 0; x < peaks.length; x++) {
            const amp = peaks[x] * mid * 0.9
            if (amp > 0.5)
                ctx.fillRect(x, mid - amp, 1, amp * 2)
        }
    }
}
