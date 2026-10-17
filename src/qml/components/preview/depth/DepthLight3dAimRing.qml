import QtQuick
import Drift

// Spot aim ring in the 3D view.
Rectangle {
    id: ring

    required property var source
    required property var overlay

    visible: ring.source.values.spot === true
    width: 14
    height: 14
    radius: 7
    x: ring.source.ax - width / 2
    y: ring.source.ay - height / 2
    color: "transparent"
    border.width: 2
    border.color: aimArea.containsMouse || aimArea.pressed
                  ? Theme.primary : (ring.source.values.color || "#ffffff")

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
            const p = aimArea.mapToItem(ring.overlay, mouse.x, mouse.y)
            const aim = EditorState.preview.aimDepthLight3d(ring.source.modelData.effect,
                                                            p.x / ring.overlay.sx, p.y / ring.overlay.sy)
            if (aim.aimX === undefined)
                return
            ring.source.liveAimX = p.x
            ring.source.liveAimY = p.y
            ring.overlay.writeParam(ring.source.prefix + "aimX", aim.aimX)
            ring.overlay.writeParam(ring.source.prefix + "aimY", aim.aimY)
        }
        onReleased: { ring.source.clearLive(); ring.overlay.endInteraction() }
        onCanceled: { ring.source.clearLive(); ring.overlay.endInteraction() }
    }
}
