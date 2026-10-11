import QtQuick
import Drift
import "../.."
import ".."

// Navigating the camera output: wheel zoom about the cursor with Ctrl, middle-drag pan, and the
// composition guides on the canvas. Takes only the middle button, so left-drags still reach the
// clip handles; in crop mode CropOverlay has the same gestures and takes them first.
Item {
    id: mode

    // The PreviewViewport this view navigates.
    property PreviewViewport viewport

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.ArrowCursor

        property real lastX: 0
        property real lastY: 0

        onPressed: (mouse) => {
            lastX = mouse.x
            lastY = mouse.y
        }
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            mode.viewport.panX += mouse.x - lastX
            mode.viewport.panY += mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y
        }

        // Ctrl-less scrolls are explicitly rejected so they keep propagating: a MouseArea accepts
        // wheel events even with no onWheel bound.
        onWheel: (wheel) => {
            if (!(wheel.modifiers & Qt.ControlModifier) || wheel.angleDelta.y === 0) {
                wheel.accepted = false
                return
            }
            mode.viewport.zoomAt(wheel.x, wheel.y, wheel.angleDelta.y > 0 ? 1.15 : 1 / 1.15)
            wheel.accepted = true
        }
    }

    // Two-finger zoom and pan, the touch counterpart of the wheel and middle-drag above.
    PinchHandler {
        id: viewPinch
        enabled: Theme.touchInput
        target: null
        acceptedDevices: PointerDevice.TouchScreen

        property real lastScale: 1
        property point lastCentroid

        // Both signals fire for the same event; consuming the deltas makes the second call a no-op.
        function step() {
            if (!active)
                return
            const c = centroid.position
            if (activeScale !== lastScale && lastScale > 0) {
                mode.viewport.zoomAt(c.x, c.y, activeScale / lastScale)
                lastScale = activeScale
            }
            mode.viewport.panX += c.x - lastCentroid.x
            mode.viewport.panY += c.y - lastCentroid.y
            lastCentroid = c
        }

        onActiveChanged: {
            if (!active)
                return
            lastScale = activeScale
            lastCentroid = centroid.position
        }
        onActiveScaleChanged: step()
        onCentroidChanged: step()
    }

    // Drawn on the canvas itself, so it is clipped to the frame and sits under the status text.
    GuideLayer {
        parent: mode.viewport ? mode.viewport.canvas : mode
        anchors.fill: parent
    }
}
