import QtQuick
import Drift

// Dim outside the keep-rect.
Item {
    id: scrim

    required property var host
    anchors.fill: parent

    Rectangle { width: scrim.host.frameX; height: parent.height; color: Theme.c.mediaPreviewCropScrim.background }
    Rectangle {
        x: scrim.host.frameX + scrim.host.frameW
        width: Math.max(0, parent.width - x)
        height: parent.height
        color: Theme.c.mediaPreviewCropScrim.background
    }
    Rectangle {
        x: scrim.host.frameX
        width: scrim.host.frameW
        height: scrim.host.frameY
        color: Theme.c.mediaPreviewCropScrim.background
    }
    Rectangle {
        x: scrim.host.frameX
        y: scrim.host.frameY + scrim.host.frameH
        width: scrim.host.frameW
        height: Math.max(0, parent.height - y)
        color: Theme.c.mediaPreviewCropScrim.background
    }
}
