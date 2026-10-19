import QtQuick
import Drift

Item {
    property var editor
    property Item strip: null
    signal colorRequested(int index, var value)
    id: stopChip
    required property int index
    readonly property var stop: editor.shownStops[index] || ({ "pos": 0, "color": "#ffffffff" })
    readonly property bool dragging: editor.dragIndex === index
    width: 32
    height: 32
    x: Math.round(Math.max(0, Math.min(1, Number(stop.pos))) * strip.width) - width / 2
    z: dragging ? 2 : 1

    Rectangle {
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: Theme.c.gradientStopChip.radius
        color: stopChip.stop.color
        border.width: stopChip.dragging || chipMouse.containsMouse ? Theme.c.gradientStopChip.borderWidthFocus : Theme.c.gradientStopChip.borderWidth
        border.color: stopChip.dragging || chipMouse.containsMouse ? Theme.c.gradientStopChip.borderActive : Theme.c.gradientStopChip.borderHover
        scale: stopChip.dragging ? 1.15 : 1
        Behavior on scale {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }

    ThemedToolTip {
        text: qsTr("Drag to move, tap for colour, hold or right-click to remove")
        visible: chipMouse.containsMouse && !stopChip.dragging
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        property real pressX: 0
        property bool moved: false
        property bool removed: false
        property bool pressedByTouch: false

        onPressed: mouse => {
            pressedByTouch = mouse.source !== Qt.MouseEventNotSynthesized
            moved = false
            removed = false
            if (mouse.button === Qt.RightButton) {
                removed = true
                editor.removeStop(stopChip.index)
                return
            }
            pressX = mapToItem(strip, mouse.x, 0).x
        }
        onPositionChanged: mouse => {
            if (!pressed || removed || !(mouse.buttons & Qt.LeftButton))
                return
            const sx = mapToItem(strip, mouse.x, 0).x
            if (!moved && Math.abs(sx - pressX) < 3)
                return
            if (!moved) {
                moved = true
                editor.dragStops = editor.cloneStops(editor.stops)
                editor.dragIndex = stopChip.index
                EditorState.beginPreviewDrag(qsTr("Move gradient stop"))
            }
            const next = editor.cloneStops(editor.dragStops)
            next[stopChip.index].pos = Math.max(0, Math.min(1, sx / strip.width))
            editor.dragStops = next
            editor.previewGradient({ "stops": next })
        }
        onReleased: mouse => {
            if (removed)
                return
            if (moved) {
                editor.previewGradient({ "stops": editor.dragStops })
                editor.dragIndex = -1
                EditorState.commitPreviewDrag()
                return
            }
            if (mouse.button === Qt.LeftButton) {
                stopChip.colorRequested(stopChip.index, stopChip.stop.color)
            }
        }
        onCanceled: {
            if (moved) {
                editor.dragIndex = -1
                EditorState.cancelPreviewDrag()
            }
        }
        onPressAndHold: {
            if (!pressedByTouch || moved || removed)
                return
            removed = true
            editor.removeStop(stopChip.index)
        }
    }
}
