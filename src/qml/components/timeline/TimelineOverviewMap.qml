import QtQuick
import Drift

// Flattened content map: one thin band per track, each clip drawn in its type's colour.
//
// Painted rather than instantiated. This was a Rectangle per clip in the whole project, none
// of them cullable, each re-running its x and width bindings on every edit — for a strip
// where most blocks are a pixel wide. One item now, repainted on the revision counter, and
// fed a flat array of numbers from C++ rather than walking the clip graph in JS.
Canvas {
    id: contentMap

    property var host
    property var panel

    anchors.fill: parent

    // [lane, typeCode, startSeconds, durationSeconds] per clip.
    property var blocks: []
    property int laneCount: 1
    // The scale the blocks are drawn at, folding in both the project duration and this
    // strip's width.
    readonly property real pps: host.overviewPxPerSecond
    readonly property int revision: EditorState.tracksRevision

    function refresh() {
        if (!host.visible)
            return
        blocks = EditorState.timelineOverviewBlocks()
        laneCount = Math.max(1, EditorState.timelineOverviewLaneCount())
        requestPaint()
    }

    onRevisionChanged: refresh()
    onPpsChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: refresh()

    Connections {
        target: contentMap.host
        function onVisibleChanged() { contentMap.refresh() }
    }

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (!panel || host.width <= 0)
            return
        const top = 3
        const available = Math.max(1, host.height - 7)
        // One pixel of gap between bands, so adjacent tracks stay countable.
        const laneHeight = Math.max(2, available / contentMap.laneCount - 1)
        const laneStride = available / contentMap.laneCount
        const blocks = contentMap.blocks
        for (let i = 0; i + 3 < blocks.length; i += 4) {
            ctx.fillStyle = host.blockColor(blocks[i + 1])
            ctx.fillRect(blocks[i + 2] * contentMap.pps, top + blocks[i] * laneStride,
                         Math.max(1, blocks[i + 3] * contentMap.pps), laneHeight)
        }
    }
}
