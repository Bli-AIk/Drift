import QtQuick
import Drift

// Crop frame over the fitted picture. Only shown while the Crop tab is open.
Item {
    id: cropHost

    // AndroidMediaPreview: cropX/Y/W/H, saving, cropRatioLocked.
    required property var preview

    readonly property real frameX: preview.cropX * width
    readonly property real frameY: preview.cropY * height
    readonly property real frameW: preview.cropW * width
    readonly property real frameH: preview.cropH * height
    readonly property real minFrac: 0.08

    function setCrop(nx, ny, nw, nh) {
        const min = cropHost.minFrac
        nw = Math.max(min, Math.min(1, nw))
        nh = Math.max(min, Math.min(1, nh))
        nx = Math.max(0, Math.min(1 - nw, nx))
        ny = Math.max(0, Math.min(1 - nh, ny))
        cropHost.preview.cropX = nx
        cropHost.preview.cropY = ny
        cropHost.preview.cropW = nw
        cropHost.preview.cropH = nh
    }

    AndroidMediaCropShade {
        anchors.fill: parent
        frameX: cropHost.frameX
        frameY: cropHost.frameY
        frameW: cropHost.frameW
        frameH: cropHost.frameH
    }

    Rectangle {
        x: cropHost.frameX
        y: cropHost.frameY
        width: cropHost.frameW
        height: cropHost.frameH
        color: "transparent"
        border.width: Theme.c.androidMediaCropOverlay.borderWidth
        border.color: Theme.c.androidMediaCropOverlay.border
    }

    MouseArea {
        x: cropHost.frameX
        y: cropHost.frameY
        width: cropHost.frameW
        height: cropHost.frameH
        enabled: !cropHost.preview.saving
        property real grabX: 0
        property real grabY: 0
        onPressed: (mouse) => {
            grabX = mouse.x
            grabY = mouse.y
            Haptics.pickUp()
        }
        onReleased: Haptics.drop()
        onCanceled: Haptics.drop()
        onPositionChanged: (mouse) => {
            if (!pressed || cropHost.width <= 0)
                return
            const dx = (mouse.x - grabX) / cropHost.width
            const dy = (mouse.y - grabY) / cropHost.height
            cropHost.setCrop(cropHost.preview.cropX + dx, cropHost.preview.cropY + dy,
                             cropHost.preview.cropW, cropHost.preview.cropH)
        }
    }

    Repeater {
        model: [
            { x: 0, y: 0, dx: -1, dy: -1 },
            { x: 0.5, y: 0, dx: 0, dy: -1 },
            { x: 1, y: 0, dx: 1, dy: -1 },
            { x: 0, y: 0.5, dx: -1, dy: 0 },
            { x: 1, y: 0.5, dx: 1, dy: 0 },
            { x: 0, y: 1, dx: -1, dy: 1 },
            { x: 0.5, y: 1, dx: 0, dy: 1 },
            { x: 1, y: 1, dx: 1, dy: 1 }
        ]
        delegate: AndroidMediaCropGrip {
            host: cropHost
            preview: cropHost.preview
        }
    }
}
