import QtQuick
import Drift

// A corner or edge of the bin-preview crop. Fingers, not a mouse pointer:
// the desktop grip is 10px. `host` is the crop overlay (frame geometry and
// setCrop); `preview` is AndroidMediaPreview (the stored rect and the lock).
Rectangle {
    id: grip

    required property var modelData
    required property var host
    required property var preview

    readonly property int gripSize: 20

    width: gripSize
    height: gripSize
    radius: Theme.radiusXs
    color: Theme.primary
    x: host.frameX + modelData.x * host.frameW - width / 2
    y: host.frameY + modelData.y * host.frameH - height / 2
    z: 2

    MouseArea {
        anchors.fill: parent
        anchors.margins: -14
        enabled: !grip.preview.saving
        preventStealing: true
        property real startX: 0
        property real startY: 0
        property real startW: 1
        property real startH: 1
        property real origX: 0
        property real origY: 0
        onPressed: {
            startX = grip.preview.cropX
            startY = grip.preview.cropY
            startW = grip.preview.cropW
            startH = grip.preview.cropH
            origX = mouseX
            origY = mouseY
            Haptics.pickUp()
        }
        onPositionChanged: {
            if (!pressed || grip.host.width <= 0)
                return
            const dx = (mouseX - origX) / grip.host.width
            const dy = (mouseY - origY) / grip.host.height
            let nx = startX
            let ny = startY
            let nw = startW
            let nh = startH
            if (grip.preview.cropRatioLocked) {
                let size
                if (modelData.dx !== 0 && modelData.dy !== 0)
                    size = Math.abs(dx) >= Math.abs(dy)
                           ? startW + modelData.dx * dx
                           : startH + modelData.dy * dy
                else if (modelData.dx !== 0)
                    size = startW + modelData.dx * dx
                else
                    size = startH + modelData.dy * dy
                size = Math.max(grip.host.minFrac, Math.min(1, size))
                nx = modelData.dx < 0 ? startX + startW - size
                   : modelData.dx > 0 ? startX : startX + (startW - size) / 2
                ny = modelData.dy < 0 ? startY + startH - size
                   : modelData.dy > 0 ? startY : startY + (startH - size) / 2
                grip.host.setCrop(nx, ny, size, size)
                return
            }
            if (modelData.dx < 0) {
                nx = startX + dx
                nw = startW - dx
            } else if (modelData.dx > 0) {
                nw = startW + dx
            }
            if (modelData.dy < 0) {
                ny = startY + dy
                nh = startH - dy
            } else if (modelData.dy > 0) {
                nh = startH + dy
            }
            grip.host.setCrop(nx, ny, nw, nh)
        }
        onReleased: Haptics.drop()
        onCanceled: Haptics.drop()
    }
}
