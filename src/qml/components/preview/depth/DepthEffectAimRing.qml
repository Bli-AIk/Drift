import QtQuick
import Drift

// Spot aim ring.
Rectangle {
    id: ring

    required property var source
    required property var frame
    required property var overlay

    visible: ring.source.isLight && ring.source.values.spot
    width: 16
    height: 16
    radius: Theme.c.depthEffectAimRing.radius
    x: ring.source.ax * ring.frame.width - width / 2
    y: ring.source.ay * ring.frame.height - height / 2
    color: "transparent"
    border.width: Theme.c.depthEffectAimRing.borderWidth
    border.color: aimArea.containsMouse || aimArea.pressed
                  ? Theme.c.depthEffectAimRing.borderHover : (ring.source.values.color || Theme.c.depthEffectAimRing.border)

    MouseArea {
        id: aimArea
        anchors.fill: parent
        anchors.margins: -Theme.spacingSm
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        preventStealing: true

        onPressed: {
            ring.overlay.interacting = true
            EditorState.beginPreviewDrag(qsTr("Aim light"))
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const p = ring.overlay.framePoint(aimArea, mouse)
            ring.source.liveAimX = Math.max(0, Math.min(1, p.x))
            ring.source.liveAimY = Math.max(0, Math.min(1, p.y))
            ring.overlay.writeParam(ring.source.modelData.effect, ring.source.prefix + "aimX", ring.source.liveAimX)
            ring.overlay.writeParam(ring.source.modelData.effect, ring.source.prefix + "aimY", ring.source.liveAimY)
        }
        onReleased: { ring.source.clearLive(); ring.overlay.endInteraction() }
        onCanceled: { ring.source.clearLive(); ring.overlay.endInteraction() }
    }
}
