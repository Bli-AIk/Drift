import QtQuick
import Drift

Rectangle {
    property var host
    property Item plotItem: null
    id: root
    required property int index
    readonly property var point: host.points[index]
    readonly property bool isEnd: index === 0 || index === host.points.length - 1

    width: 11
    height: 11
    radius: Theme.c.speedCurveKnob.radius
    z: 4
    color: host.selectedPoint === index ? Theme.c.speedCurveKnob.backgroundSelected : Theme.c.speedCurveKnob.background
    border.width: Theme.c.speedCurveKnob.borderWidth
    border.color: Theme.c.speedCurveKnob.border
    x: point.pos * plotItem.width - width / 2
    y: host.yForSpeed(point.speed, plotItem.height) - height / 2

    // DragHandler reports translation from where the drag began, so the
    // values it is applied to have to be frozen there too — reading the live
    // point would compound each move into the next and make the knob bolt.
    property real basePos: 0
    property real baseSpeed: 1

    TapHandler {
        margin: Theme.touchInput ? 11 : 0
        onTapped: host.selectedPoint = root.index
    }

    DragHandler {
        margin: Theme.touchInput ? 11 : 0
        target: null
        onActiveChanged: {
            if (active) {
                root.basePos = root.point.pos
                root.baseSpeed = root.point.speed
                host.selectedPoint = root.index
            } else {
                host.commit()
            }
        }
        onTranslationChanged: {
            if (!active)
                return
            const next = host.clonePoints()
            const point = next[root.index]
            // Ends anchor the ramp's span, so they only move in speed.
            if (!root.isEnd) {
                const lo = next[root.index - 1].pos + 0.002
                const hi = next[root.index + 1].pos - 0.002
                point.pos = Math.max(lo, Math.min(hi,
                    root.basePos + translation.x / plotItem.width))
            }
            point.speed = host.speedForY(
                host.yForSpeed(root.baseSpeed, plotItem.height) + translation.y,
                plotItem.height)
            host.points = next
        }
    }
}
