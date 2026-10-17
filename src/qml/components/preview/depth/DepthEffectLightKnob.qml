import QtQuick
import Drift

// Light knob: drag to move across the frame, scroll to move nearer or farther.
Rectangle {
    id: knob

    required property var source
    required property var frame
    required property var overlay

    visible: knob.source.isLight
    width: knob.source.knobSize
    height: knob.source.knobSize
    radius: width / 2
    x: knob.source.hx * knob.frame.width - width / 2
    y: knob.source.hy * knob.frame.height - height / 2
    color: knob.source.values.color || "#ffffff"
    border.width: 2
    border.color: lightArea.containsMouse || lightArea.pressed
                  ? Theme.primary : Theme.primaryForeground

    Text {
        anchors.centerIn: parent
        text: knob.source.modelData.light || ""
        // Dark on the light's own colour: every default is a pale tint.
        color: "#1a1a1a"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
    }

    MouseArea {
        id: lightArea
        anchors.fill: parent
        anchors.margins: -Theme.spacingSm
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true

        onPressed: {
            knob.overlay.interacting = true
            EditorState.beginPreviewDrag(qsTr("Move light"))
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            // Lights may sit off the frame, as far as the parameters reach.
            const p = knob.overlay.framePoint(lightArea, mouse)
            knob.source.liveX = Math.max(-0.5, Math.min(1.5, p.x))
            knob.source.liveY = Math.max(-0.5, Math.min(1.5, p.y))
            knob.overlay.writeParam(knob.source.modelData.effect, knob.source.prefix + "x", knob.source.liveX)
            knob.overlay.writeParam(knob.source.modelData.effect, knob.source.prefix + "y", knob.source.liveY)
        }
        onReleased: { knob.source.clearLive(); knob.overlay.endInteraction() }
        onCanceled: { knob.source.clearLive(); knob.overlay.endInteraction() }

        // Scrolling up brings the light towards the camera; Shift for fine steps.
        onWheel: (wheel) => {
            const step = (wheel.modifiers & Qt.ShiftModifier) !== 0 ? 0.01 : 0.05
            const z = Math.max(-1, Math.min(1, knob.source.hz - Math.sign(wheel.angleDelta.y) * step))
            EditorState.beginPreviewDrag(qsTr("Move light"))
            knob.overlay.writeParam(knob.source.modelData.effect, knob.source.prefix + "z", z)
            EditorState.commitPreviewDrag()
            wheel.accepted = true
        }
    }
}
