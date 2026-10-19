import QtQuick
import Drift

// The inner edge — the one `h` actually moves. Drawn as a bar rather than
// a dot because it spans the whole width, like the thing it resizes.
Rectangle {
    id: edge

    required property bool atTop
    required property var bars
    required property var frame
    required property var overlay

    visible: edge.bars.isSelected
    width: Theme.spacingLg * 2
    height: Theme.spacingSm
    radius: Theme.c.maskOverlayBarEdge.radius
    x: (parent.width - width) / 2
    y: (edge.atTop ? parent.height : 0) - height / 2
    color: edgeArea.containsMouse || edgeArea.pressed
           ? Theme.c.maskOverlayBarEdge.backgroundHover : Theme.c.maskOverlayBarEdge.background
    border.width: Theme.c.maskOverlayBarEdge.borderWidth
    border.color: edgeArea.containsMouse || edgeArea.pressed
                  ? Theme.c.maskOverlayBarEdge.borderHover : Theme.c.maskOverlayBarEdge.border

    MouseArea {
        id: edgeArea
        anchors.fill: parent
        anchors.margins: -Theme.spacingMd
        hoverEnabled: true
        cursorShape: Qt.SizeVerCursor
        preventStealing: true
        onWheel: (wheel) => { wheel.accepted = false }

        onPressed: {
            edge.overlay.interacting = true
            EditorState.beginPreviewDrag(qsTr("Mask changed"))
        }

        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const p = mapToItem(edge.frame, mouse.x, mouse.y)
            // Both bands come from one number, so the bottom edge is
            // measured from the bottom of the frame.
            const depth = edge.atTop ? p.y : edge.frame.height - p.y
            edge.bars.writeHeight(2.0 * depth / Math.max(1, edge.frame.height))
        }

        function finish() {
            edge.bars.liveH = -1
            edge.overlay.endInteraction()
        }

        onReleased: finish()
        onCanceled: finish()
    }
}
