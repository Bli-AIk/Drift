import QtQuick
import Drift

// Canvas crop tool. Lives outside the (clipped) canvas rect so the
// crop frame can be dragged past the current edges to grow the
// output. Values are kept in project pixels; committing hands the
// rect to AppController, which rebases clip layout so nothing
// moves or rescales — content outside the new frame is simply lost.
Item {
    id: root

    // The PreviewViewport (zoom/pan math + reset) and the canvas
    // rectangle whose on-screen geometry the crop frame maps against.
    property var previewViewport
    property var previewCanvas

    readonly property int projW: { void EditorState.tracksRevision; return Math.max(1, EditorState.projectFile.projectWidth()) }
    readonly property int projH: { void EditorState.tracksRevision; return Math.max(1, EditorState.projectFile.projectHeight()) }
    // Project px → viewport px.
    readonly property real pxScale: root.previewCanvas.width / projW

    property real cropX: 0
    property real cropY: 0
    property real cropW: projW
    property real cropH: projH

    readonly property int outW: Math.round(cropW)
    readonly property int outH: Math.round(cropH)

    // Hint bookkeeping. Set as each input is first used; once all
    // three are known the hint retires and does not come back, so
    // reopening the tool is not nagging.
    property bool didResize: false
    property bool didZoom: false
    property bool didPan: false
    property bool hintDismissed: false
    onDidResizeChanged: maybeDismissHint()
    onDidZoomChanged: maybeDismissHint()
    onDidPanChanged: maybeDismissHint()

    function maybeDismissHint() {
        if (didResize && didZoom && didPan)
            hintDismissed = true
    }
    readonly property bool changed: outW !== projW || outH !== projH
                                    || Math.round(cropX) !== 0 || Math.round(cropY) !== 0

    function reset() {
        cropX = 0
        cropY = 0
        cropW = projW
        cropH = projH
    }

    function apply() {
        if (changed)
            EditorState.applyCanvasCrop(cropX, cropY, cropW, cropH)
        EditorState.preview.canvasCropMode = false
    }

    // Screen-space crop frame, relative to the viewport.
    readonly property real frameX: root.previewCanvas.x + cropX * pxScale
    readonly property real frameY: root.previewCanvas.y + cropY * pxScale
    readonly property real frameW: cropW * pxScale
    readonly property real frameH: cropH * pxScale

    // Navigation sits below the handles in stacking order, and takes
    // only the middle button, so left-drags still reach the grips.
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
            root.previewViewport.panX += mouse.x - lastX
            root.previewViewport.panY += mouse.y - lastY
            lastX = mouse.x
            lastY = mouse.y
            root.didPan = true
        }

        // Zoom lives here rather than in a sibling WheelHandler: a
        // MouseArea accepts wheel events even with no onWheel bound,
        // so a separate handler behind it never got them. Ctrl-less
        // scrolls are explicitly rejected so they keep propagating.
        onWheel: (wheel) => {
            if (!Theme.primaryModifierPressed(wheel.modifiers)
                    || wheel.angleDelta.y === 0) {
                wheel.accepted = false
                return
            }
            root.previewViewport.zoomAt(wheel.x, wheel.y,
                            wheel.angleDelta.y > 0 ? 1.15 : 1 / 1.15)
            root.didZoom = true
            wheel.accepted = true
        }
    }

    // Two-finger zoom and pan, the touch counterpart of the wheel and middle-drag above.
    PinchHandler {
        id: viewPinch
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
                root.previewViewport.zoomAt(c.x, c.y, activeScale / lastScale)
                lastScale = activeScale
            }
            root.previewViewport.panX += c.x - lastCentroid.x
            root.previewViewport.panY += c.y - lastCentroid.y
            lastCentroid = c
            root.didZoom = true
            root.didPan = true
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

    // Everything outside the crop frame is discarded, so dim it.
    // Four bands rather than a mask: no shader, no clipping cost.
    CropOverlayScrim {
        frameX: root.frameX
        frameY: root.frameY
        frameW: root.frameW
        frameH: root.frameH
    }

    CropOverlayFrame {
        x: root.frameX
        y: root.frameY
        width: root.frameW
        height: root.frameH

        // Rule-of-thirds inside the crop frame, the usual cue for
        // judging a reframe.
        CropOverlayThirdGuides { }
    }

    // Eight drag handles: 4 edges then 4 corners. `dx`/`dy` say
    // which edges each handle moves (-1 = left/top, +1 = right/bottom).
    Repeater {
        model: [
            { dx: -1, dy:  0, cursor: Qt.SizeHorCursor },
            { dx:  1, dy:  0, cursor: Qt.SizeHorCursor },
            { dx:  0, dy: -1, cursor: Qt.SizeVerCursor },
            { dx:  0, dy:  1, cursor: Qt.SizeVerCursor },
            { dx: -1, dy: -1, cursor: Qt.SizeFDiagCursor },
            { dx:  1, dy:  1, cursor: Qt.SizeFDiagCursor },
            { dx:  1, dy: -1, cursor: Qt.SizeBDiagCursor },
            { dx: -1, dy:  1, cursor: Qt.SizeBDiagCursor }
        ]

        delegate: CropOverlayGrip {
            crop: root
        }
    }

    // First-run hint. The crop tool has three non-obvious inputs and
    // no menu surface to discover them from, so they are spelled out
    // while the tool is open. Fades once the user has driven all
    // three, and stays gone for the rest of the session.
    CropOverlayHint {
        hintDismissed: root.hintDismissed
        didResize: root.didResize
        didZoom: root.didZoom
        didPan: root.didPan
    }

    // Readout + commit, pinned under the crop frame but kept inside
    // the viewport so it stays reachable at any crop size.
    Row {
        spacing: Theme.spacingMd
        x: Math.max(0, Math.min(root.width - width,
                                root.frameX + (root.frameW - width) / 2))
        y: Math.max(0, Math.min(root.height - height,
                                root.frameY + root.frameH + Theme.spacingMd))

        CropOverlaySizeBadge {
            label: root.outW + "×" + root.outH
                   + "   " + Math.round(root.previewViewport.userZoom * 100) + "%"
        }

        ThemedButton {
            variant: "secondary"
            text: qsTr("Fit view")
            tooltip: qsTr("Recentre and reset zoom")
            enabled: root.previewViewport.userZoom !== 1.0 || root.previewViewport.panX !== 0 || root.previewViewport.panY !== 0
            onClicked: root.previewViewport.resetView()
        }

        ThemedButton {
            variant: "secondary"
            text: qsTr("Reset")
            tooltip: qsTr("Reset crop to the full video size")
            enabled: root.changed
            onClicked: root.reset()
        }

        ThemedButton {
            variant: "primary"
            text: qsTr("Apply")
            onClicked: root.apply()
        }
    }
}
