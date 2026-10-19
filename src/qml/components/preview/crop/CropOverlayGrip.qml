import QtQuick
import Drift

// One edge or corner grip. dx/dy say which edges it moves
// (-1 = left/top, +1 = right/bottom).
Rectangle {
    id: grip

    required property var modelData
    // The CropOverlay.
    required property var crop

    readonly property real hs: Theme.spacingLg
    width: hs
    height: hs
    radius: Theme.c.cropOverlayGrip.radius
    color: gripArea.containsMouse || gripArea.pressed
           ? Theme.c.cropOverlayGrip.backgroundHover : Theme.c.cropOverlayGrip.background
    border.width: Theme.c.cropOverlayGrip.borderWidth
    border.color: gripArea.containsMouse || gripArea.pressed
                  ? Theme.c.cropOverlayGrip.borderHover : Theme.c.cropOverlayGrip.border

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    x: grip.crop.frameX + (modelData.dx === 0 ? grip.crop.frameW / 2
                             : (modelData.dx < 0 ? 0 : grip.crop.frameW)) - hs / 2
    y: grip.crop.frameY + (modelData.dy === 0 ? grip.crop.frameH / 2
                             : (modelData.dy < 0 ? 0 : grip.crop.frameH)) - hs / 2

    property real startX: 0
    property real startY: 0
    property real startCropX: 0
    property real startCropY: 0
    property real startCropW: 0
    property real startCropH: 0

    MouseArea {
        id: gripArea
        anchors.fill: parent
        // Generous invisible margin: the visible dot stays
        // small enough not to hide the frame it sits on.
        anchors.margins: -Theme.spacingMd
        hoverEnabled: true
        cursorShape: grip.modelData.cursor

        // Zooming onto a vertex means the cursor is over a
        // grip; without this the grip would eat the wheel
        // event exactly where zoom is most wanted.
        onWheel: (wheel) => { wheel.accepted = false }

        onPressed: (mouse) => {
            const p = mapToItem(grip.crop, mouse.x, mouse.y)
            grip.startX = p.x
            grip.startY = p.y
            grip.startCropX = grip.crop.cropX
            grip.startCropY = grip.crop.cropY
            grip.startCropW = grip.crop.cropW
            grip.startCropH = grip.crop.cropH
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const p = mapToItem(grip.crop, mouse.x, mouse.y)
            const ddx = (p.x - grip.startX) / grip.crop.pxScale
            const ddy = (p.y - grip.startY) / grip.crop.pxScale
            grip.crop.didResize = true

            if (grip.modelData.dx < 0) {
                // Dragging the left edge moves the origin and
                // shrinks the width by the same amount.
                const nx = Math.min(grip.startCropX + ddx,
                                    grip.startCropX + grip.startCropW - 16)
                grip.crop.cropX = nx
                grip.crop.cropW = grip.startCropX + grip.startCropW - nx
            } else if (grip.modelData.dx > 0) {
                grip.crop.cropW = Math.max(16, grip.startCropW + ddx)
            }

            if (grip.modelData.dy < 0) {
                const ny = Math.min(grip.startCropY + ddy,
                                    grip.startCropY + grip.startCropH - 16)
                grip.crop.cropY = ny
                grip.crop.cropH = grip.startCropY + grip.startCropH - ny
            } else if (grip.modelData.dy > 0) {
                grip.crop.cropH = Math.max(16, grip.startCropH + ddy)
            }
        }
    }
}
