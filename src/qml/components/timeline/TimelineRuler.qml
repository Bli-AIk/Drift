import QtQuick
import Drift

// Time ticks in the upper half of the seek strip. Only ticks that intersect the
// viewport are instantiated — a 2h timeline at 1× zoom would otherwise create
// thousands of Items.
Item {
    id: ruler

    property TimelinePanel panel
    property Flickable view

    width: parent.width
    height: Theme.timelineRulerHeight
    z: 0

    readonly property real tickStepPx: panel.tickStepSeconds * panel.pxPerSecond
    readonly property int tickIndexMax: Math.max(0,
        Math.ceil(view.contentWidth / Math.max(1, tickStepPx)))
    readonly property int firstVisibleTick: Math.max(0,
        Math.floor(view.contentX / Math.max(1, tickStepPx)) - 1)
    readonly property int visibleTickCount: Math.min(
        tickIndexMax - firstVisibleTick + 1,
        Math.ceil(view.width / Math.max(1, tickStepPx)) + 3)

    Repeater {
        model: Math.max(0, ruler.visibleTickCount)
        delegate: TimelineRulerTick {
            firstTick: ruler.firstVisibleTick
            stepSeconds: ruler.panel.tickStepSeconds
            pxPerSecond: ruler.panel.pxPerSecond
            formatTick: ruler.panel.formatTick
            rulerHeight: ruler.height
        }
    }
}
