import QtQuick
import QtQuick.Controls.Basic
import Drift

// Shared vertical-drag tracker used by the header and empty body chrome.
// Tracks overlay coordinates so moving the panel does not cancel the gesture.
MouseArea {
    id: dragArea

    property bool stealTouches: false
    // The sheet that owns the height maths: beginDrag, updateDrag, finishDrag, collapse.
    required property var sheet

    property real startGlobalY: 0
    property real startHeight: 0
    property real lastGlobalY: 0
    property real lastT: 0
    property real velocityY: 0

    preventStealing: stealTouches
    acceptedButtons: Qt.LeftButton

    function globalY(mouse) {
        return mapToItem(Overlay.overlay, mouse.x, mouse.y).y
    }

    onPressed: (mouse) => {
        const state = sheet.beginDrag(globalY(mouse))
        startGlobalY = state.startGlobalY
        startHeight = state.startHeight
        lastGlobalY = startGlobalY
        lastT = Date.now()
        velocityY = 0
    }

    onPositionChanged: (mouse) => {
        if (!pressed)
            return
        const gy = globalY(mouse)
        const now = Date.now()
        const dt = Math.max(1, now - lastT)
        sheet.updateDrag(startGlobalY, startHeight, gy)
        velocityY = (gy - lastGlobalY) / dt * 1000
        lastGlobalY = gy
        lastT = now
    }

    onReleased: {
        sheet._dragging = false
        sheet.finishDrag(sheet.panelHeight, velocityY)
    }

    onCanceled: {
        sheet._dragging = false
        sheet.collapse()
    }
}
