import QtQuick
import Drift

// One resize grip. The same frame the canvas crop tool and TransformOverlay use.
Rectangle {
    id: grip

    required property var modelData
    required property var mask
    required property var frame
    required property var overlay

    readonly property real hs: Theme.spacingLg
    readonly property bool isCorner: modelData.dx !== 0 && modelData.dy !== 0

    width: hs
    height: hs
    radius: Theme.radiusXs
    color: gripArea.containsMouse || gripArea.pressed
           ? Theme.primaryForeground : Theme.primary
    border.width: Theme.borderWidth
    border.color: gripArea.containsMouse || gripArea.pressed
                  ? Theme.primary : Theme.primaryForeground

    x: (modelData.dx === 0 ? grip.mask.width / 2
                           : (modelData.dx < 0 ? 0 : grip.mask.width)) - hs / 2
    y: (modelData.dy === 0 ? grip.mask.height / 2
                           : (modelData.dy < 0 ? 0 : grip.mask.height)) - hs / 2

    // Press point in clip-frame coordinates. The grip rides the box as it
    // resizes, so deltas are measured against the frame, which stands still.
    property real startPx: 0
    property real startPy: 0

    // Resize about the fixed opposite edge/corner. The maths runs in the box's
    // own axes so a rotated mask grows along the direction the grip points;
    // the resulting centre shift is rotated back into the clip frame at the end.
    function resizeTo(px, py, modifiers) {
        const dxSign = grip.modelData.dx
        const dySign = grip.modelData.dy
        const a = grip.mask.rotation * Math.PI / 180
        const ddx = (px - grip.startPx) / Math.max(1, grip.frame.width)
        const ddy = (py - grip.startPy) / Math.max(1, grip.frame.height)
        // Clip axes -> box axes.
        const lx = ddx * Math.cos(a) + ddy * Math.sin(a)
        const ly = -ddx * Math.sin(a) + ddy * Math.cos(a)

        let w = Math.max(0.01, grip.mask.dragStartW + lx * dxSign)
        let h = Math.max(0.01, grip.mask.dragStartH + ly * dySign)

        // Shift locks the ratio on a corner drag.
        if (grip.isCorner && (modifiers & Qt.ShiftModifier) !== 0) {
            const s = Math.max(w / Math.max(0.01, grip.mask.dragStartW),
                               h / Math.max(0.01, grip.mask.dragStartH))
            w = Math.max(0.01, grip.mask.dragStartW * s)
            h = Math.max(0.01, grip.mask.dragStartH * s)
        }

        // Keeping the anchor still means the centre moves by half the size
        // change, toward the grip, in box axes.
        const shiftX = (w - grip.mask.dragStartW) / 2 * dxSign
        const shiftY = (h - grip.mask.dragStartH) / 2 * dySign
        grip.mask.liveX = grip.mask.dragStartX
                      + shiftX * Math.cos(a) - shiftY * Math.sin(a)
        grip.mask.liveY = grip.mask.dragStartY
                      + shiftX * Math.sin(a) + shiftY * Math.cos(a)
        grip.mask.liveW = w
        grip.mask.liveH = h
        grip.mask.writeLive()
    }

    MouseArea {
        id: gripArea
        anchors.fill: parent
        // Generous invisible margin: the visible dot stays small enough not to
        // hide the box edge it sits on.
        anchors.margins: -Theme.spacingMd
        hoverEnabled: true
        cursorShape: grip.modelData.cursor
        // The body DragHandler would otherwise take the grab once the drag
        // threshold is passed, turning a resize into a move.
        preventStealing: true
        // Zooming with the pointer on a grip should still zoom.
        onWheel: (wheel) => { wheel.accepted = false }

        onPressed: (mouse) => {
            const p = mapToItem(grip.frame, mouse.x, mouse.y)
            grip.startPx = p.x
            grip.startPy = p.y
            grip.mask.dragStartX = grip.mask.mx
            grip.mask.dragStartY = grip.mask.my
            grip.mask.dragStartW = grip.mask.mw
            grip.mask.dragStartH = grip.mask.mh
            grip.mask.liveX = grip.mask.dragStartX
            grip.mask.liveY = grip.mask.dragStartY
            grip.mask.liveW = grip.mask.dragStartW
            grip.mask.liveH = grip.mask.dragStartH
            grip.overlay.interacting = true
            grip.mask.forceActiveFocus()
            EditorState.beginPreviewDrag(qsTr("Mask changed"))
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const p = mapToItem(grip.frame, mouse.x, mouse.y)
            grip.resizeTo(p.x, p.y, mouse.modifiers)
        }

        onReleased: { grip.mask.clearLive(); grip.overlay.endInteraction() }
        onCanceled: { grip.mask.clearLive(); grip.overlay.endInteraction() }
    }
}
