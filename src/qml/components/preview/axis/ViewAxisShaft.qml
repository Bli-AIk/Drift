import QtQuick
import Drift

// Shaft from the widget centre to a positive axis end.
Rectangle {
    id: shaft

    required property bool shown
    required property real originX
    required property real originY
    required property real tipX
    required property real tipY
    required property color ink

    visible: shaft.shown
    x: shaft.originX
    y: shaft.originY - height / 2
    width: Math.hypot(shaft.tipX - shaft.originX, shaft.tipY - shaft.originY)
    height: Theme.c.viewAxisShaft.strokeWidth
    color: shaft.ink
    transformOrigin: Item.Left
    rotation: Math.atan2(shaft.tipY - shaft.originY, shaft.tipX - shaft.originX) * 180 / Math.PI
}
