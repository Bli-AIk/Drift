import QtQuick
import Drift

// A thin draggable bar on a time strip. Reports its x in the parent's coordinates.
Item {
    id: root

    property real centerX: 0
    property color color: "transparent"
    property real barWidth: 4
    // How far either side of the bar a mouse can grab; a touch press gets the wider zone.
    property real mouseReach: 6
    property real touchReach: 16

    signal pressedDown()
    signal moved(real parentX)
    signal released()

    x: root.centerX - root.barWidth / 2
    width: root.barWidth
    height: parent.height
    z: 4

    Rectangle {
        anchors.fill: parent
        color: root.color
        radius: Math.min(2, root.barWidth / 2)
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -root.touchReach
        anchors.rightMargin: -root.touchReach
        cursorShape: Qt.SizeHorCursor
        preventStealing: true
        onPressed: (mouse) => {
            const touch = mouse.source !== Qt.MouseEventNotSynthesized
            if (!touch && Math.abs(mouse.x - width / 2) > root.mouseReach + root.barWidth / 2) {
                mouse.accepted = false
                return
            }
            root.pressedDown()
        }
        onPositionChanged: (mouse) => {
            if (pressed)
                root.moved(mapToItem(root.parent, mouse.x, mouse.y).x)
        }
        onReleased: root.released()
    }
}
