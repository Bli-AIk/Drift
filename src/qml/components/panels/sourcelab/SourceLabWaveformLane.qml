import QtQuick
import Drift

// Peaks of the source's audio over the visible window. One row per channel, or all channels
// folded into a single envelope.
Canvas {
    id: root

    property string path: ""
    property real viewStart: 0
    property real viewDur: 1
    property bool perChannel: false

    property var peaks: ({ channels: 0 })
    readonly property int bucketCount: Math.max(1, Math.min(4096, Math.ceil(root.width)))
    readonly property color wave: Theme.c.sourceLabStrip.waveform

    function refresh() {
        if (root.path.length === 0 || root.viewDur <= 0 || root.width <= 0) {
            root.peaks = { channels: 0 }
            return
        }
        root.peaks = EditorState.waveformChannelPeaksRange(root.path, root.viewStart, root.viewDur,
                                                          root.bucketCount)
    }

    opacity: Theme.c.sourceLabStrip.waveformOpacity

    onViewStartChanged: settle.restart()
    onViewDurChanged: settle.restart()
    onWidthChanged: settle.restart()
    onPathChanged: settle.restart()
    onPeaksChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()
    onPerChannelChanged: root.requestPaint()
    onWaveChanged: root.requestPaint()

    Timer {
        id: settle
        interval: 60
        onTriggered: root.refresh()
    }

    Connections {
        target: EditorState
        function onWaveformRangeReady(readyPath) {
            if (readyPath === root.path)
                settle.restart()
        }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const d = root.peaks
        if (!d || !d.channels || d.channels <= 0 || !d.peaks)
            return
        const rows = root.perChannel ? d.channels : 1
        const rowH = height / rows
        const n = d.buckets
        ctx.fillStyle = root.wave
        const w = Math.max(1, Math.floor(width))
        for (let row = 0; row < rows; row++) {
            const mid = rowH * row + rowH / 2
            for (let x = 0; x < w; x++) {
                const b = Math.min(n - 1, Math.floor(x * n / w))
                let peak = 0
                if (root.perChannel) {
                    peak = d.peaks[row * n + b]
                } else {
                    for (let c = 0; c < d.channels; c++)
                        peak = Math.max(peak, d.peaks[c * n + b])
                }
                const amp = peak * rowH / 2 * 0.92
                if (amp > 0.5)
                    ctx.fillRect(x, mid - amp, 1, amp * 2)
            }
        }
    }
}
