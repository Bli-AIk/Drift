import QtQuick
import Drift

// Resize grip on one edge of a subtitle cue. `edge` is -1 (start) or +1 (end).
Item {
    id: grip

    property var lane
    property var cue
    property int edge: -1

    anchors.fill: parent

    Rectangle {
        x: grip.edge < 0 ? 0 : parent.width - width
        width: grip.cue.gripW
        height: parent.height
        color: grip.cue.isSelected ? Theme.c.subtitleCueEdgeGrip.background : "transparent"
        opacity: 0.6
    }

    Item {
        x: grip.edge < 0
           ? ((Theme.touchInput && !grip.cue.narrowTouch) ? -grip.cue.edgeHitW / 2 : 0)
           : parent.width - ((Theme.touchInput && !grip.cue.narrowTouch)
                             ? grip.cue.edgeHitW / 2 : grip.cue.edgeHitW)
        width: grip.cue.edgeHitW
        height: parent.height
        HoverHandler { cursorShape: Qt.SizeHorCursor }
        DragHandler {
            target: null
            acceptedDevices: grip.cue.isSelected
                ? PointerDevice.AllDevices
                : PointerDevice.Mouse | PointerDevice.TouchPad | PointerDevice.Stylus
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: {
                if (active)
                    grip.cue.startEdit()
                else
                    grip.cue.finishEdit()
            }
            onTranslationChanged: {
                if (grip.edge < 0) {
                    let ns = grip.cue.editStart + translation.x / grip.lane.pxPerSecond
                    ns = grip.lane.snap(ns, grip.lane.snapTargets(grip.cue.index))
                    ns = grip.lane.clampVal(ns, grip.lane.loBound(grip.cue.index),
                                            grip.cue.editEnd - grip.lane.minCueDur)
                    grip.cue.dragX = grip.lane.xForSeconds(ns)
                    grip.cue.dragW = (grip.cue.editEnd - ns) * grip.lane.pxPerSecond
                    grip.lane.commitCue(grip.cue.index, ns, grip.cue.editEnd)
                } else {
                    let ne = grip.cue.editEnd + translation.x / grip.lane.pxPerSecond
                    ne = grip.lane.snap(ne, grip.lane.snapTargets(grip.cue.index))
                    ne = grip.lane.clampVal(ne, grip.cue.editStart + grip.lane.minCueDur,
                                            grip.lane.hiBound(grip.cue.index))
                    grip.cue.dragW = (ne - grip.cue.editStart) * grip.lane.pxPerSecond
                    grip.lane.commitCue(grip.cue.index, grip.cue.editStart, ne)
                }
            }
        }
    }
}
