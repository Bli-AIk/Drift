import QtQuick
import Drift

// Crop editor over the picture. Drag state is local; the recipe is written when the drag ends.
// Doubles as the `editor` object MediaPreviewCropFrame and MediaPreviewCropGrip expect.
Item {
    id: root

    // The picture's painted size inside this item, and its aspect (display space, so a rotated
    // source is already accounted for).
    required property real paintedWidth
    required property real paintedHeight
    property bool editing: true

    readonly property var recipe: EditorState.sourceLab.recipe
    readonly property real frameAspect: paintedHeight > 0 ? paintedWidth / paintedHeight : 1
    // Width over height of the crop box, in normalized units; 0 when the shape is free.
    readonly property real lockedRatio: {
        const a = root.aspectValue(root.recipe.aspect ?? "free")
        return a > 0 && root.frameAspect > 0 ? a / root.frameAspect : 0
    }

    property real cropX: 0
    property real cropY: 0
    property real cropW: 1
    property real cropH: 1
    readonly property bool cropRatioLocked: false

    function aspectValue(text) {
        if (text === "free")
            return 0
        const parts = text.split(":")
        const a = parseFloat(parts[0])
        const b = parts.length > 1 ? parseFloat(parts[1]) : 1
        return a > 0 && b > 0 ? a / b : 0
    }

    function loadFromRecipe() {
        const c = root.recipe.crop
        if (!c)
            return
        root.cropX = c.x
        root.cropY = c.y
        root.cropW = c.width
        root.cropH = c.height
    }

    function commitCrop() {
        EditorState.sourceLab.setRecipeValue("crop", Qt.rect(root.cropX, root.cropY, root.cropW, root.cropH))
    }

    // Largest box of the locked shape that fits, centred on the current one.
    function fitToRatio() {
        const k = root.lockedRatio
        if (k <= 0 || root.paintedHeight <= 0)
            return
        if (Math.abs(root.cropW / root.cropH - k) < 0.01 * k)
            return
        const cx = root.cropX + root.cropW / 2
        const cy = root.cropY + root.cropH / 2
        let w = Math.min(root.cropW, root.cropH * k)
        let h = w / k
        w = Math.max(host.minFrac, Math.min(1, w))
        h = w / k
        if (h > 1) {
            h = 1
            w = k
        }
        root.cropW = w
        root.cropH = h
        root.cropX = Math.max(0, Math.min(1 - w, cx - w / 2))
        root.cropY = Math.max(0, Math.min(1 - h, cy - h / 2))
        root.commitCrop()
    }

    onRecipeChanged: loadFromRecipe()
    onLockedRatioChanged: fitToRatio()
    Component.onCompleted: loadFromRecipe()

    Item {
        id: host

        x: (root.width - root.paintedWidth) / 2
        y: (root.height - root.paintedHeight) / 2
        width: root.paintedWidth
        height: root.paintedHeight

        readonly property real frameX: root.cropX * width
        readonly property real frameY: root.cropY * height
        readonly property real frameW: root.cropW * width
        readonly property real frameH: root.cropH * height
        readonly property real minFrac: 0.08

        // The grips propose a free-form box; with a locked shape the other side follows and the
        // edge the user is not dragging stays put.
        function setCrop(nx, ny, nw, nh) {
            const min = host.minFrac
            const k = root.lockedRatio
            const eps = 1e-6
            nw = Math.max(min, Math.min(1, nw))
            nh = Math.max(min, Math.min(1, nh))
            if (k > 0 && (Math.abs(nw - root.cropW) > eps || Math.abs(nh - root.cropH) > eps)) {
                const leftSame = Math.abs(nx - root.cropX) < eps
                const rightSame = Math.abs(nx + nw - root.cropX - root.cropW) < eps
                const topSame = Math.abs(ny - root.cropY) < eps
                const bottomSame = Math.abs(ny + nh - root.cropY - root.cropH) < eps
                const byWidth = Math.abs(nw - root.cropW) * root.paintedWidth
                                >= Math.abs(nh - root.cropH) * root.paintedHeight
                let w = byWidth ? nw : nh * k
                let h = byWidth ? nw / k : nh
                if (w > 1) {
                    w = 1
                    h = 1 / k
                }
                if (h > 1) {
                    h = 1
                    w = k
                }
                if (w < min) {
                    w = min
                    h = min / k
                }
                if (h < min) {
                    h = min
                    w = min * k
                }
                w = Math.min(1, w)
                h = Math.min(1, h)
                if (leftSame && rightSame)
                    nx = root.cropX + (root.cropW - w) / 2
                else if (rightSame)
                    nx = root.cropX + root.cropW - w
                else if (leftSame)
                    nx = root.cropX
                if (topSame && bottomSame)
                    ny = root.cropY + (root.cropH - h) / 2
                else if (bottomSame)
                    ny = root.cropY + root.cropH - h
                else if (topSame)
                    ny = root.cropY
                nw = w
                nh = h
            }
            root.cropX = Math.max(0, Math.min(1 - nw, nx))
            root.cropY = Math.max(0, Math.min(1 - nh, ny))
            root.cropW = nw
            root.cropH = nh
        }

        MediaPreviewCropScrim {
            host: host
        }

        MediaPreviewCropFrame {
            host: host
            editor: root
            editing: root.editing
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
            MediaPreviewCropGrip {
                host: host
                editor: root
                editing: root.editing
            }
        }
    }
}
