import QtQuick
import Drift

// Drag grip: the text field grows and shrinks with it.
// Measured against the inspector, not the grip: the grip moves as the field grows.
Item {
    id: root

    property real fieldHeight: 96
    property Item measureItem: null
    signal heightEdited(real height)

    width: parent ? parent.width : implicitWidth
    height: 10

    Rectangle {
        anchors.centerIn: parent
        width: 32
        height: 3
        radius: 1.5
        color: gripArea.pressed || gripArea.containsMouse ? Theme.mutedForeground : Theme.panelBorder
    }

    MouseArea {
        id: gripArea
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.SizeVerCursor
        property real pressY: 0
        property real pressHeight: 0
        onPressed: mouse => {
            pressY = mapToItem(root.measureItem, mouse.x, mouse.y).y
            pressHeight = root.fieldHeight
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return
            const dy = mapToItem(root.measureItem, mouse.x, mouse.y).y - pressY
            root.heightEdited(Math.max(56, Math.min(400, pressHeight + dy)))
        }
    }
}
