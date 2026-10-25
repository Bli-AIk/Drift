import QtQuick
import Drift
import "SourceLabTime.js" as SourceLabTime

// The zoomed strip: ruler, markers, range band, then the filmstrip over the waveform (a tall
// per-channel waveform for audio). Scrubs the preview, edits the In/Out trim and moves ranges
// and markers. All times are source seconds; xOf and tOf map them onto the visible window.
Rectangle {
    id: root

    required property var panel
    required property var asset

    readonly property var lab: EditorState.sourceLab
    readonly property var preview: EditorState.assetPreview
    readonly property real viewStart: root.panel.viewStart
    readonly property real viewDur: Math.max(0.001, root.panel.viewDur)
    readonly property real pxPerSecond: root.width / root.viewDur
    readonly property real fps: root.panel.fps
    readonly property bool isAudio: root.panel.isAudio
    readonly property real rulerHeight: 22
    readonly property real bandHeight: 18
    readonly property real laneTop: root.rulerHeight + root.bandHeight
    readonly property real minSpan: root.isAudio ? 0.02 : 1 / root.fps
    readonly property real trimIn: root.lab.recipe.trimIn ?? 0
    readonly property real trimOut: (root.lab.recipe.trimOut ?? -1) < 0
                                    ? root.panel.duration : root.lab.recipe.trimOut
    readonly property real playX: root.xOf(root.preview.position)

    // Ruler step: the smallest of these whose ticks stay readable.
    readonly property var tickSteps: {
        const steps = [1 / root.fps, 2 / root.fps, 5 / root.fps, 10 / root.fps]
        for (const s of [0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600])
            steps.push(s)
        return root.isAudio ? steps.slice(4).concat([0.01, 0.02, 0.05, 0.1, 0.2]).sort((a, b) => a - b)
                            : steps
    }
    readonly property real tickStep: {
        for (const s of root.tickSteps) {
            if (s * root.pxPerSecond >= 84)
                return s
        }
        return root.tickSteps[root.tickSteps.length - 1]
    }
    readonly property real firstTick: Math.ceil(root.viewStart / root.tickStep) * root.tickStep

    function xOf(t) {
        return (t - root.viewStart) * root.pxPerSecond
    }

    function tOf(x) {
        return root.viewStart + x / root.pxPerSecond
    }

    function formatTick(t) {
        if (root.isAudio)
            return SourceLabTime.formatClock(t, root.tickStep < 1 ? 2 : 0)
        const text = SourceLabTime.format(t, root.fps)
        return root.tickStep < 1 ? text : text.slice(0, 8)
    }

    // Frames always; markers, range edges, the trim and the playhead win within a few pixels.
    // `exclude` names the thing being dragged (trimIn, trimOut, range:<id>, marker:<id>).
    function snap(t, exclude) {
        const clamped = Math.max(0, Math.min(root.panel.duration, t))
        if (root.panel.snapTargets) {
            const reach = 8 / root.pxPerSecond
            let best = -1
            let bestDistance = reach
            const consider = (id, at) => {
                if (id === exclude)
                    return
                const distance = Math.abs(at - clamped)
                if (distance < bestDistance) {
                    best = at
                    bestDistance = distance
                }
            }
            consider("playhead", root.preview.position)
            consider("trimIn", root.trimIn)
            consider("trimOut", root.trimOut)
            for (const r of root.lab.ranges) {
                consider("range:" + r.id, r.in)
                consider("range:" + r.id, r.out)
            }
            for (const m of root.lab.markers)
                consider("marker:" + m.id, m.time)
            if (best >= 0)
                return best
        }
        if (root.isAudio)
            return root.panel.zeroCrossSnap ? root.lab.nearestZeroCrossing(clamped, 0.01) : clamped
        return root.preview.snapToFrame(clamped)
    }

    function scrubTo(x) {
        root.preview.seek(root.snap(root.tOf(Math.max(0, Math.min(root.width, x))), ""))
    }

    color: Theme.c.sourceLabStrip.background
    border.width: Theme.c.sourceLabStrip.borderWidth
    border.color: Theme.c.sourceLabStrip.border
    radius: Theme.c.sourceLabStrip.radius
    clip: true

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: (mouse) => root.scrubTo(mouse.x)
        onPositionChanged: (mouse) => {
            if (pressed)
                root.scrubTo(mouse.x)
        }
    }

    WheelHandler {
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => root.panel.zoomAt(event.angleDelta.y > 0 ? 1.25 : 0.8,
                                              root.tOf(point.position.x))
    }
    WheelHandler {
        acceptedModifiers: Qt.NoModifier
        onWheel: (event) => {
            const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                          ? event.angleDelta.x : event.angleDelta.y
            root.panel.scrollTo(root.viewStart - delta / 120 * root.viewDur * 0.1)
        }
    }
    PinchHandler {
        id: pinch
        target: null
        property real startDur: 1
        property real anchorTime: 0
        onActiveChanged: {
            if (active) {
                startDur = root.panel.viewDur
                anchorTime = root.tOf(centroid.position.x)
            }
        }
        onActiveScaleChanged: {
            if (active)
                root.panel.zoomTo(startDur / activeScale, anchorTime, centroid.position.x / root.width)
        }
    }

    Item {
        id: ruler
        width: parent.width
        height: root.rulerHeight
        clip: true

        Item {
            x: root.xOf(root.firstTick)
            height: parent.height
            Repeater {
                model: Math.floor(root.viewDur / root.tickStep) + 2
                MediaPreviewRulerTick {
                    rangeStart: root.firstTick
                    step: root.tickStep
                    pxPerSecond: root.pxPerSecond
                    formatTick: (seconds) => root.formatTick(seconds)
                }
            }
        }

        MediaPreviewPlayheadCap {
            playX: root.playX
        }

        Repeater {
            model: root.lab.markers
            SourceLabHandle {
                id: flag
                required property var modelData
                property real liveTime: modelData.time
                centerX: root.xOf(flag.liveTime)
                barWidth: 8
                mouseReach: 8
                color: Theme.c.sourceLabStrip.marker
                onMoved: (parentX) => flag.liveTime = root.snap(root.tOf(parentX), "marker:" + modelData.id)
                onReleased: {
                    if (Math.abs(flag.liveTime - modelData.time) > 1e-6)
                        root.lab.moveMarker(modelData.id, flag.liveTime)
                    flag.liveTime = Qt.binding(() => flag.modelData.time)
                }
            }
        }
    }

    Item {
        id: band
        y: root.rulerHeight
        width: parent.width
        height: root.bandHeight
        clip: true

        Repeater {
            model: root.lab.ranges
            SourceLabRangeSpan {
                strip: root
            }
        }
    }

    Item {
        id: lane
        y: root.laneTop
        width: parent.width
        height: parent.height - root.laneTop
        clip: true

        ClipFilmstrip {
            id: filmstrip
            visible: !root.isAudio && filmstripPath.length > 0
            width: parent.width
            height: root.panel.hasWaveform ? Math.round(parent.height * 0.62) : parent.height
            filmstripPath: root.asset.filmstripPath ?? ""
            frameWidth: Math.max(1, Math.round(height * 16 / 9))
            sourcePath: root.asset.path ?? ""
            rotationCorrection: ((root.asset.effectiveRotation ?? 0) - (root.asset.rotationDegrees ?? 0) + 360) % 360
            inPoint: root.viewStart
            outPoint: root.viewStart + root.viewDur
            sourceDuration: root.panel.duration
        }

        SourceLabWaveformLane {
            y: root.isAudio ? 0 : filmstrip.height
            width: parent.width
            height: root.isAudio ? parent.height : parent.height - filmstrip.height
            visible: root.panel.hasWaveform
            path: root.panel.hasWaveform ? (root.asset.path ?? "") : ""
            viewStart: root.viewStart
            viewDur: root.viewDur
            perChannel: root.isAudio
        }

        Repeater {
            model: root.lab.markers
            Rectangle {
                required property var modelData
                x: root.xOf(modelData.time)
                width: 1
                height: parent.height
                color: Theme.c.sourceLabStrip.marker
                opacity: 0.7
            }
        }

        MediaPreviewTrimShade {
            leading: true
            edge: root.xOf(root.trimIn)
            span: root.width
        }
        MediaPreviewTrimShade {
            leading: false
            edge: root.xOf(root.trimOut)
            span: root.width
        }
        MediaPreviewTrimSpan {
            inX: root.xOf(root.trimIn)
            outX: root.xOf(root.trimOut)
        }

        SourceLabHandle {
            centerX: root.xOf(root.trimIn)
            visible: centerX >= -4 && centerX <= root.width + 4
            barWidth: 8
            color: Theme.c.mediaPreviewTrimHandle.background
            onMoved: (parentX) => {
                const t = root.snap(root.tOf(parentX), "trimIn")
                const limit = root.trimOut - root.minSpan
                const next = Math.max(0, Math.min(limit, t))
                root.lab.setRecipeValue("trimIn", next)
                root.preview.seek(next)
            }
        }
        SourceLabHandle {
            centerX: root.xOf(root.trimOut)
            visible: centerX >= -4 && centerX <= root.width + 4
            barWidth: 8
            color: Theme.c.mediaPreviewTrimHandle.background
            onMoved: (parentX) => {
                const t = root.snap(root.tOf(parentX), "trimOut")
                const next = Math.min(root.panel.duration, Math.max(root.trimIn + root.minSpan, t))
                root.lab.setRecipeValue("trimOut", next >= root.panel.duration - 0.0005 ? -1 : next)
                root.preview.seek(next)
            }
        }
    }

    MediaPreviewPlayheadLine {
        playX: root.playX
        visible: root.playX >= 0 && root.playX <= root.width
    }
}
