import QtQuick
import Drift

// Crop border, and the drag that moves the keep-rect.
Rectangle {
    id: frame

    // cropHost (frame geometry and setCrop) and the preview window (cropX/Y/W/H).
    required property var host
    required property var editor
    required property bool editing

    x: frame.host.frameX
    y: frame.host.frameY
    width: frame.host.frameW
    height: frame.host.frameH
    color: "transparent"
    border.width: Theme.borderWidthFocus
    border.color: Theme.primary

    MouseArea {
        anchors.fill: parent
        enabled: frame.editing
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property real grabX: 0
        property real grabY: 0
        onPressed: (mouse) => {
            grabX = mouse.x
            grabY = mouse.y
        }
        onPositionChanged: (mouse) => {
            if (!pressed || frame.host.width <= 0)
                return
            const dx = (mouse.x - grabX) / frame.host.width
            const dy = (mouse.y - grabY) / frame.host.height
            frame.host.setCrop(frame.editor.cropX + dx, frame.editor.cropY + dy,
                               frame.editor.cropW, frame.editor.cropH)
        }
    }
}
