import QtQuick
import Drift

// Everything outside the crop frame is discarded, so dim it.
// Four bands rather than a mask: no shader, no clipping cost.
Item {
    id: scrim

    required property real frameX
    required property real frameY
    required property real frameW
    required property real frameH

    anchors.fill: parent

    Rectangle {
        color: Theme.c.cropOverlayScrim.background
        opacity: Theme.c.cropOverlayScrim.opacity
        x: 0
        y: 0
        width: Math.max(0, scrim.frameX)
        height: parent.height
    }
    Rectangle {
        color: Theme.c.cropOverlayScrim.background
        opacity: Theme.c.cropOverlayScrim.opacity
        x: scrim.frameX + scrim.frameW
        y: 0
        width: Math.max(0, scrim.width - x)
        height: parent.height
    }
    Rectangle {
        color: Theme.c.cropOverlayScrim.background
        opacity: Theme.c.cropOverlayScrim.opacity
        x: scrim.frameX
        y: 0
        width: Math.max(0, scrim.frameW)
        height: Math.max(0, scrim.frameY)
    }
    Rectangle {
        color: Theme.c.cropOverlayScrim.background
        opacity: Theme.c.cropOverlayScrim.opacity
        x: scrim.frameX
        y: scrim.frameY + scrim.frameH
        width: Math.max(0, scrim.frameW)
        height: Math.max(0, scrim.height - y)
    }
}
