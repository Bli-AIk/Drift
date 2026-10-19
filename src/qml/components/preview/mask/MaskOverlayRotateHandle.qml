import QtQuick
import Drift

// Rotation handle, 28px above the box.
Rectangle {
    id: knob

    // The mask box delegate, the clip frame it is normalized to, and the overlay.
    required property var mask
    required property var frame
    required property var overlay

    visible: knob.mask.editable && knob.mask.isSelected
    width: Theme.spacingLg
    height: Theme.spacingLg
    radius: width / 2
    color: rotateArea.containsMouse || rotateArea.pressed
           ? Theme.c.maskOverlayRotateHandle.backgroundHover : Theme.c.maskOverlayRotateHandle.background
    border.width: Theme.c.maskOverlayRotateHandle.borderWidth
    border.color: rotateArea.containsMouse || rotateArea.pressed
                  ? Theme.c.maskOverlayRotateHandle.borderHover : Theme.c.maskOverlayRotateHandle.border
    x: parent.width / 2 - width / 2
    y: -28 - height / 2

    MouseArea {
        id: rotateArea
        anchors.fill: parent
        anchors.margins: -Theme.spacingMd
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        preventStealing: true
        onWheel: (wheel) => { wheel.accepted = false }

        onPressed: {
            knob.overlay.interacting = true
            knob.mask.forceActiveFocus()
            EditorState.beginPreviewDrag(qsTr("Mask changed"))
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            // Angle is measured in the clip frame, so map through it rather than
            // through the rotating box.
            const p = mapToItem(knob.frame, mouse.x, mouse.y)
            const cx = knob.mask.mx * knob.frame.width
            const cy = knob.mask.my * knob.frame.height
            let deg = Math.atan2(p.y - cy, p.x - cx) * 180 / Math.PI + 90
            if ((mouse.modifiers & Qt.ShiftModifier) !== 0)
                deg = Math.round(deg / 15) * 15
            knob.mask.liveRotation = deg
            knob.mask.writeLive()
        }

        onReleased: { knob.mask.clearLive(); knob.overlay.endInteraction() }
        onCanceled: { knob.mask.clearLive(); knob.overlay.endInteraction() }
    }
}
