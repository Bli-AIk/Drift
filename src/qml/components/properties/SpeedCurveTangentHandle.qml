import QtQuick
import Drift

Rectangle {
    property var host
    property Item plotItem: null
    id: root
    required property int index
    readonly property bool isOut: index === 1
    readonly property real dx: isOut ? host.selected.outDx : host.selected.inDx
    readonly property real dy: isOut ? host.selected.outDy : host.selected.inDy

    // Frozen at drag start, for the same reason the knobs freeze theirs.
    property real baseDx: 0
    property real baseDy: 0

    width: 9
    height: 9
    radius: 4.5
    z: 5
    color: Theme.panelBackground
    border.width: 2
    border.color: Theme.mutedForeground
    x: (host.selected.pos + dx) * plotItem.width - width / 2
    y: host.yForSpeed(host.selected.speed + dy, plotItem.height) - height / 2

    DragHandler {
        margin: Theme.touchInput ? 12 : 0
        target: null
        onActiveChanged: {
            if (active) {
                root.baseDx = root.dx
                root.baseDy = root.dy
            } else {
                host.commit()
            }
        }
        onTranslationChanged: {
            if (!active)
                return
            const next = host.clonePoints()
            const point = next[host.selectedPoint]
            const baseX = (point.pos + root.baseDx) * plotItem.width
            const baseY = host.yForSpeed(point.speed + root.baseDy, plotItem.height)
            const newDx = (baseX + translation.x) / plotItem.width - point.pos
            const newDy = host.speedForY(baseY + translation.y, plotItem.height)
                          - point.speed

            if (root.isOut) {
                point.outDx = Math.max(0, newDx)
                point.outDy = newDy
            } else {
                point.inDx = Math.min(0, newDx)
                point.inDy = newDy
            }
            // A continuous point keeps its two tangents mirrored, so the
            // ramp passes through without a kink.
            if (!point.corner) {
                if (root.isOut) {
                    point.inDx = -point.outDx
                    point.inDy = -point.outDy
                } else {
                    point.outDx = -point.inDx
                    point.outDy = -point.inDy
                }
            }
            host.points = next
        }
    }
}
