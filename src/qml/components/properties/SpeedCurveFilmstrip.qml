import QtQuick
import Drift

Rectangle {
    id: strip
    width: parent.width
    height: 56
    radius: Theme.c.speedCurveFilmstrip.radius
    color: Theme.c.speedCurveFilmstrip.background
    border.width: Theme.c.speedCurveFilmstrip.borderWidth
    border.color: Theme.c.speedCurveFilmstrip.border
    clip: true

    ClipFilmstrip {
        anchors.fill: parent
        anchors.margins: Theme.c.speedCurveFilmstrip.borderWidth
        filmstripPath: EditorState.speedCurve.filmstripPath
        // One pass of the strip's eight frames across the clip, rather than the repeating
        // tile the timeline draws — here the x axis *is* the source.
        frameWidth: width / frameCount
        // The strip's frames are sampled across the whole media file, but this axis covers
        // only the clip's trimmed window, which is what the curve is plotted over. Without
        // the mapping a trimmed clip shows the wrong frames under the ramp.
        inPoint: EditorState.speedCurve.sourceStart
        outPoint: EditorState.speedCurve.sourceStart + EditorState.speedCurve.sourceDuration
        sourceDuration: EditorState.speedCurve.mediaDuration
    }

    Canvas {
        id: waveCanvas
        anchors.fill: parent
        anchors.margins: Theme.c.speedCurveFilmstrip.borderWidth
        visible: !EditorState.speedCurve.filmstripPath

        // The x axis here is the clip's trimmed source window, the same one the filmstrip
        // above spans and the same one the curve is plotted over — not the whole file.
        function sourcePeaks(path) {
            return EditorState.waveformPeaksForSourceRange(
                       path, EditorState.speedCurve.sourceStart,
                       EditorState.speedCurve.sourceDuration)
        }

        property var peaks: EditorState.speedCurve.clipPath
                            ? sourcePeaks(EditorState.speedCurve.clipPath) : []

        onPeaksChanged: requestPaint()
        onWidthChanged: requestPaint()

        Connections {
            target: EditorState
            function onWaveformReady(path) {
                if (path === EditorState.speedCurve.clipPath)
                    waveCanvas.peaks = waveCanvas.sourcePeaks(path)
            }
        }

        readonly property color waveformColor: Theme.c.speedCurveFilmstrip.waveform
        onWaveformColorChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!peaks || peaks.length === 0)
                return
            ctx.fillStyle = waveformColor
            const mid = height / 2
            const w = Math.max(1, Math.floor(width))
            for (let x = 0; x < w; x++) {
                const i0 = Math.floor(x * peaks.length / w)
                const i1 = Math.max(i0 + 1, Math.floor((x + 1) * peaks.length / w))
                let peak = 0
                for (let i = i0; i < i1 && i < peaks.length; i++)
                    peak = Math.max(peak, peaks[i])
                const amp = peak * mid * 0.9
                if (amp > 0.5)
                    ctx.fillRect(x, mid - amp, 1, amp * 2)
            }
        }
    }

    Rectangle {
        width: Theme.playheadLineWidth
        height: parent.height
        color: Theme.c.speedCurveFilmstrip.accent
        x: EditorState.speedCurve.sourcePosition * parent.width
    }

    MouseArea {
        anchors.fill: parent
        onPressed: function (mouse) {
            EditorState.speedCurve.seekAtSource(mouse.x / width)
        }
        onPositionChanged: function (mouse) {
            if (pressed)
                EditorState.speedCurve.seekAtSource(mouse.x / width)
        }
    }
}
