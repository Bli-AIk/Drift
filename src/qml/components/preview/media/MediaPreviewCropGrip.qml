import QtQuick
import Drift

// One corner or edge of the bin-preview crop.
Rectangle {
    id: grip

    required property var modelData
    required property var host
    required property var editor
    required property bool editing

    readonly property int gripSize: Theme.touchUi ? 16 : 10
    width: gripSize
    height: gripSize
    radius: Theme.c.mediaPreviewCropGrip.radius
    color: Theme.c.mediaPreviewCropGrip.background
    x: grip.host.frameX + modelData.x * grip.host.frameW - width / 2
    y: grip.host.frameY + modelData.y * grip.host.frameH - height / 2
    z: 2

    MouseArea {
        anchors.fill: parent
        anchors.margins: Theme.touchUi ? -10 : -6
        enabled: grip.editing
        cursorShape: {
            if (grip.modelData.dx !== 0 && grip.modelData.dy !== 0)
                return (grip.modelData.dx === grip.modelData.dy)
                       ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
            return grip.modelData.dx !== 0 ? Qt.SizeHorCursor : Qt.SizeVerCursor
        }
        property real startX: 0
        property real startY: 0
        property real startW: 1
        property real startH: 1
        property real origX: 0
        property real origY: 0
        onPressed: {
            startX = grip.editor.cropX
            startY = grip.editor.cropY
            startW = grip.editor.cropW
            startH = grip.editor.cropH
            const pos = mapToItem(grip.host, mouseX, mouseY)
            origX = pos.x
            origY = pos.y
        }
        onPositionChanged: {
            if (!pressed || grip.host.width <= 0)
                return
            const pos = mapToItem(grip.host, mouseX, mouseY)
            const dx = (pos.x - origX) / grip.host.width
            const dy = (pos.y - origY) / grip.host.height
            let nx = startX
            let ny = startY
            let nw = startW
            let nh = startH
            if (grip.editor.cropRatioLocked) {
                let size
                if (grip.modelData.dx !== 0 && grip.modelData.dy !== 0)
                    size = Math.abs(dx) >= Math.abs(dy)
                           ? startW + grip.modelData.dx * dx
                           : startH + grip.modelData.dy * dy
                else if (grip.modelData.dx !== 0)
                    size = startW + grip.modelData.dx * dx
                else
                    size = startH + grip.modelData.dy * dy
                size = Math.max(grip.host.minFrac, Math.min(1, size))
                nx = grip.modelData.dx < 0 ? startX + startW - size
                   : grip.modelData.dx > 0 ? startX : startX + (startW - size) / 2
                ny = grip.modelData.dy < 0 ? startY + startH - size
                   : grip.modelData.dy > 0 ? startY : startY + (startH - size) / 2
                grip.host.setCrop(nx, ny, size, size)
                return
            }
            if (grip.modelData.dx < 0) {
                nx = Math.max(0, Math.min(startX + startW - grip.host.minFrac, startX + dx))
                nw = startX + startW - nx
            } else if (grip.modelData.dx > 0) {
                nw = Math.max(grip.host.minFrac, Math.min(1 - startX, startW + dx))
            }
            if (grip.modelData.dy < 0) {
                ny = Math.max(0, Math.min(startY + startH - grip.host.minFrac, startY + dy))
                nh = startY + startH - ny
            } else if (grip.modelData.dy > 0) {
                nh = Math.max(grip.host.minFrac, Math.min(1 - startY, startH + dy))
            }
            grip.host.setCrop(nx, ny, nw, nh)
        }
    }
}
