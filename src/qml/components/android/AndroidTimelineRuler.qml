import QtQuick
import Drift

// The time ruler above the tracks. Only the ticks that intersect the viewport
// are built; the rest of the timeline is not a row of items.
Item {
    id: ruler

    property real pxPerSecond: 0
    property real tickStepSeconds: 1
    property real contentWidth: 0
    property real contentX: 0
    property real viewWidth: 0
    property var formatTick: function(seconds) { return "" }

    width: parent.width
    height: Theme.timelineRulerHeight
    z: 0

    readonly property real tickStepPx: ruler.tickStepSeconds * ruler.pxPerSecond
    readonly property int tickIndexMax: Math.max(0,
        Math.ceil(ruler.contentWidth / Math.max(1, tickStepPx)))
    readonly property int firstVisibleTick: Math.max(0,
        Math.floor(ruler.contentX / Math.max(1, tickStepPx)) - 1)
    readonly property int visibleTickCount: Math.min(
        tickIndexMax - firstVisibleTick + 1,
        Math.ceil(ruler.viewWidth / Math.max(1, tickStepPx)) + 3)

    Repeater {
        model: Math.max(0, ruler.visibleTickCount)
        delegate: AndroidTimelineRulerTick {
            firstVisibleTick: ruler.firstVisibleTick
            tickStepSeconds: ruler.tickStepSeconds
            pxPerSecond: ruler.pxPerSecond
            formatTick: ruler.formatTick
        }
    }
}
