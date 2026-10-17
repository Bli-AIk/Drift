import QtQuick
import Drift

// One edge or corner of a selected frameItem. `dx`/`dy` on modelData say which edges
// this grip moves. `clip` is the overlay delegate that owns the live rect;
// `overlay` is AndroidTransformOverlay (snap tolerance, endInteraction).
Item {
    required property var frameItem
    required property var overlay
    id: grip
    required property var modelData

    // The touch target is the whole delegate; the dot inside it
    // stays small enough not to hide the box edge it sits on.
    width: overlay.gripTouch
    height: overlay.gripTouch

    // Corners drive both axes, edges only one — so an edge drag is
    // the deliberate way to stretch and corners keep the ratio.
    readonly property bool isCorner: modelData.dx !== 0 && modelData.dy !== 0
    // Footage has a real aspect to protect. Boxes that exist to be
    // reshaped (text, subtitles, shapes) scale freely.
    readonly property bool lockRatio: isCorner
            && (frameItem.box.kind === "video"
                || frameItem.box.kind === "image"
                || frameItem.box.kind === "composite")

    x: (modelData.dx === 0 ? frameItem.width / 2
                           : (modelData.dx < 0 ? 0 : frameItem.width)) - width / 2
    y: (modelData.dy === 0 ? frameItem.height / 2
                           : (modelData.dy < 0 ? 0 : frameItem.height)) - height / 2

    Rectangle {
        anchors.centerIn: parent
        width: overlay.gripSize
        height: overlay.gripSize
        radius: Theme.radiusXs
        color: gripArea.pressed ? Theme.primaryForeground : Theme.primary
        border.width: Theme.borderWidth
        border.color: gripArea.pressed ? Theme.primary : Theme.primaryForeground

        Behavior on color {
            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }

    // Press point in overlay coordinates. The grip rides the box as
    // it resizes, so deltas are measured against the overlay, which
    // stands still.
    property real startPx: 0
    property real startPy: 0
    // Tilted or under the camera: the grab mapped into the box's own layout px.
    property var toLocal: null
    property point startLocal: Qt.point(0, 0)
    property var startBox: null

    // Resize about the fixed anchor. The maths runs in the box's own
    // axes, so a rotated clip grows along the direction the grip
    // points; the resulting centre shift is rotated back to canvas
    // axes at the end. At rotation 0 it reduces to a plain "opposite
    // corner stays put".
    function resizeTo(px, py) {
        const dxSign = grip.modelData.dx
        const dySign = grip.modelData.dy
        const a = frameItem.layoutRotation * Math.PI / 180
        let lx = 0
        let ly = 0
        if (grip.toLocal) {
            // Through the pose, so the finger is read in the box's own plane. A
            // tilted box resizes about its centre, which is also the tilt pivot:
            // holding an edge still would drag it through depth. Doubling the
            // finger's travel in the box plane keeps the grip under the finger.
            const l = grip.toLocal(px, py)
            const k = frameItem.is3d ? 2 : 1
            lx = k * (l.x - grip.startLocal.x) / frameItem.sx
            ly = k * (l.y - grip.startLocal.y) / frameItem.sy
        } else {
            const ddx = (px - grip.startPx) / frameItem.sx
            const ddy = (py - grip.startPy) / frameItem.sy
            // Canvas axes -> box axes: the inverse of the rotation the
            // body drag applies to its translation.
            lx = ddx * Math.cos(a) + ddy * Math.sin(a)
            ly = -ddx * Math.sin(a) + ddy * Math.cos(a)
        }

        const locked = grip.lockRatio

        let w = Math.max(1, frameItem.dragStartW + lx * dxSign)
        let h = Math.max(1, frameItem.dragStartH + ly * dySign)
        if (locked) {
            // Take the scale from whichever axis the finger moved
            // further along, measured as the bigger departure from
            // the original size so it reads the same growing or
            // shrinking.
            const rw = w / frameItem.dragStartW
            const rh = h / frameItem.dragStartH
            const s = Math.abs(rw - 1) >= Math.abs(rh - 1) ? rw : rh
            w = Math.max(1, frameItem.dragStartW * s)
            h = Math.max(1, frameItem.dragStartH * s)
        }

        // Only the moving edge sticks; the anchor is already fixed.
        let guideX = -1
        let guideY = -1
        if (frameItem.canSnap) {
            // Each moving edge is snapped as it projects, through the pose,
            // parents and camera.
            const snapped = EditorState.preview.snapResize(grip.startBox, w, h, dxSign, dySign,
                                                          frameItem.is3d,
                                                          overlay.snapTolPx / frameItem.sx)
            if (locked) {
                // The axes are tied, so only the closer of the two
                // snaps wins and it sets the scale for both.
                const rx = snapped.distX >= 0 ? snapped.distX : Infinity
                const ry = snapped.distY >= 0 ? snapped.distY : Infinity
                let s = -1
                if (rx <= ry && rx < Infinity) {
                    s = snapped.width / frameItem.dragStartW
                    guideX = snapped.guideX
                } else if (ry < Infinity) {
                    s = snapped.height / frameItem.dragStartH
                    guideY = snapped.guideY
                }
                if (s > 0) {
                    w = Math.max(1, frameItem.dragStartW * s)
                    h = Math.max(1, frameItem.dragStartH * s)
                }
            } else {
                if (snapped.distX >= 0) {
                    w = snapped.width
                    guideX = snapped.guideX
                }
                if (snapped.distY >= 0) {
                    h = snapped.height
                    guideY = snapped.guideY
                }
            }
        }
        frameItem.publishGuides(guideX, guideY)

        // Keeping the anchor still means the centre moves by half the
        // size change, toward the grip, in box axes.
        const shiftX = frameItem.is3d ? 0 : (w - frameItem.dragStartW) / 2 * dxSign
        const shiftY = frameItem.is3d ? 0 : (h - frameItem.dragStartH) / 2 * dySign
        const cx = frameItem.dragStartX + frameItem.dragStartW / 2
                   + shiftX * Math.cos(a) - shiftY * Math.sin(a)
        const cy = frameItem.dragStartY + frameItem.dragStartH / 2
                   + shiftX * Math.sin(a) + shiftY * Math.cos(a)
        const x = cx - w / 2
        const y = cy - h / 2

        frameItem.liveX = x
        frameItem.liveY = y
        frameItem.liveW = w
        frameItem.liveH = h
        if (frameItem.isText && grip.isCorner) {
            // Height drives the glyph scale; an edge drag just
            // re-wraps, since the box is the wrap width.
            const size = Math.round(frameItem.dragStartPixelSize
                                    * h / Math.max(1, frameItem.dragStartH))
            EditorState.previewSetTextRect(
                frameItem.box.track,
                frameItem.box.clip,
                x, y, w, h, size)
        } else {
            EditorState.previewSetClipRect(
                frameItem.box.track,
                frameItem.box.clip,
                x, y, w, h)
        }
    }

    MouseArea {
        id: gripArea
        anchors.fill: parent
        // The delegate's body DragHandler would otherwise take the
        // grab once the drag threshold is passed, turning a resize
        // into a move.
        preventStealing: true

        onPressed: (mouse) => {
            const raw = mapToItem(overlay, mouse.x, mouse.y)
            const throughPose = frameItem.is3d || frameItem.viaCamera
            const p = throughPose ? raw : frameItem.toParentLocal(raw)
            grip.startPx = p.x
            grip.startPy = p.y
            grip.toLocal = throughPose ? frameItem.overlayToLocalMapper() : null
            if (grip.toLocal)
                grip.startLocal = grip.toLocal(p.x, p.y)
            if (frameItem.isTransform)
                overlay.movingLayerTrack = frameItem.box.track
            frameItem.dragStartX = frameItem.layoutX
            frameItem.dragStartY = frameItem.layoutY
            frameItem.dragStartW = frameItem.layoutW
            frameItem.dragStartH = frameItem.layoutH
            frameItem.dragStartPixelSize = frameItem.box.pixelSize || 64
            grip.startBox = frameItem.grabBox()
            frameItem.liveX = frameItem.dragStartX
            frameItem.liveY = frameItem.dragStartY
            frameItem.liveW = frameItem.dragStartW
            frameItem.liveH = frameItem.dragStartH
            frameItem.resizing = true
            overlay.interacting = true
            EditorState.selectClip(frameItem.box.track, frameItem.box.clip)
            frameItem.forceActiveFocus()
            EditorState.beginPreviewDrag()
            Haptics.pickUp()
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const raw = mapToItem(overlay, mouse.x, mouse.y)
            const p = grip.toLocal ? raw : frameItem.toParentLocal(raw)
            grip.resizeTo(p.x, p.y)
        }

        onReleased: grip.finishResize()
        onCanceled: grip.finishResize()
    }

    function finishResize() {
        if (!frameItem.resizing)
            return
        frameItem.resizing = false
        frameItem.liveX = -1e12
        frameItem.liveY = -1e12
        frameItem.liveW = -1
        frameItem.liveH = -1
        overlay.endInteraction()
        Haptics.drop()
    }
}
