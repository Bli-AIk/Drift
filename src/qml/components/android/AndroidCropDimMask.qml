import QtQuick
import Drift

// Everything outside the crop frame is discarded, so dim it. Four bands
// rather than a mask: no shader, no clipping cost.
Item {
    id: mask

    property real frameX: 0
    property real frameY: 0
    property real frameW: 0
    property real frameH: 0

    Rectangle {
        color: Theme.overlayColor
        opacity: 0.65
        x: 0
        y: 0
        width: Math.max(0, mask.frameX)
        height: mask.height
    }
    Rectangle {
        color: Theme.overlayColor
        opacity: 0.65
        x: mask.frameX + mask.frameW
        y: 0
        width: Math.max(0, mask.width - x)
        height: mask.height
    }
    Rectangle {
        color: Theme.overlayColor
        opacity: 0.65
        x: mask.frameX
        y: 0
        width: Math.max(0, mask.frameW)
        height: Math.max(0, mask.frameY)
    }
    Rectangle {
        color: Theme.overlayColor
        opacity: 0.65
        x: mask.frameX
        y: mask.frameY + mask.frameH
        width: Math.max(0, mask.frameW)
        height: Math.max(0, mask.height - y)
    }
}
