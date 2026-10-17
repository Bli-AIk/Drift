import QtQuick
import Drift

// The part of the picture the crop throws away.
Item {
    id: mask

    property real frameX: 0
    property real frameY: 0
    property real frameW: 0
    property real frameH: 0

    Rectangle { width: mask.frameX; height: mask.height; color: Theme.c.androidMediaCropShade.background }
    Rectangle {
        x: mask.frameX + mask.frameW
        width: Math.max(0, mask.width - x)
        height: mask.height
        color: Theme.c.androidMediaCropShade.background
    }
    Rectangle {
        x: mask.frameX
        width: mask.frameW
        height: mask.frameY
        color: Theme.c.androidMediaCropShade.background
    }
    Rectangle {
        x: mask.frameX
        y: mask.frameY + mask.frameH
        width: mask.frameW
        height: Math.max(0, mask.height - y)
        color: Theme.c.androidMediaCropShade.background
    }
}
