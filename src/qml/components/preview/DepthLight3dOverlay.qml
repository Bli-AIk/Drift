import QtQuick
import Drift
import ".."

// The 3D view's grips for the selected clip's lights: a model clip's own, or 3D Relight's over a
// clip's relief. The lights themselves (rings, spot cones, the drop to the surface) are drawn by
// the renderer; this only puts a knob on each light and a ring on each spot's aim, at the canvas
// points the engine projects them to.
//
// Dragging a knob slides the light across the view at the distance it already has, the way
// Blender's grab does, so orbiting is what moves it nearer or farther; the wheel steps it along
// the clip's own near/far axis as in 2D. Dragging an aim ring lays it on the relief, or the plane
// through a model's centre, under the pointer. Only the grips take the pointer.
Item {
    id: root

    readonly property real sx: width / Math.max(1, EditorState.projectFile.projectWidth())
    readonly property real sy: height / Math.max(1, EditorState.projectFile.projectHeight())

    // True while a grip is being dragged: rebuilding the delegates mid-drag would destroy the one
    // holding the grab.
    property bool interacting: false

    property var lights: []
    property string lightSignature: ""

    function refreshOverlay() {
        if (!visible || interacting || EditorState.playing)
            return
        const next = EditorState.preview.depthLights3d()
        lights = next
        const signature = next.map(l => l.prefix + ":" + l.spot).join("|")
        if (signature === lightSignature)
            return
        lightSignature = signature
        lightRepeater.model = next
    }

    function endInteraction() {
        EditorState.commitPreviewDrag()
        interacting = false
        Qt.callLater(refreshOverlay)
    }

    // `key` is the light's prefix plus the parameter: "fx.2.light1_x", "model3d.light1_x".
    function writeParam(key, value) {
        EditorState.previewSetClipKeyframe(EditorState.selectedTrack, EditorState.selectedClip, key,
                                           EditorState.playheadSeconds, value)
    }

    onVisibleChanged: if (visible) refreshOverlay()
    Component.onCompleted: refreshOverlay()

    Connections {
        target: EditorState
        function onTracksChanged() { root.refreshOverlay() }
        function onClipPropertiesPreviewed(trackIndex, clipIndex, keys) { root.refreshOverlay() }
        function onSelectionChanged() { root.refreshOverlay() }
        function onSelectedClipDataChanged() { root.refreshOverlay() }
        function onPlayheadSecondsChanged() {
            if (!EditorState.scrubbing)
                root.refreshOverlay()
        }
        function onScrubbingChanged() {
            if (!EditorState.scrubbing)
                root.refreshOverlay()
        }
        function onPlayingChanged() {
            if (!EditorState.playing)
                root.refreshOverlay()
        }
    }

    Connections {
        target: EditorState.preview
        function onViewChanged() { root.refreshOverlay() }
    }

    Repeater {
        id: lightRepeater

        delegate: Item {
            id: handle
            required property int index
            required property var modelData
            // Values from the latest refresh; modelData only fixes which light this is.
            readonly property var values: root.lights[index] || modelData
            readonly property string prefix: modelData.prefix

            // Where the grips sit while dragged, in overlay px, so they follow the pointer without
            // waiting for a refresh.
            property real liveX: NaN
            property real liveY: NaN
            property real liveAimX: NaN
            property real liveAimY: NaN
            readonly property real hx: isNaN(liveX) ? values.x * root.sx : liveX
            readonly property real hy: isNaN(liveY) ? values.y * root.sy : liveY
            readonly property real ax: isNaN(liveAimX) ? (values.aimX || 0) * root.sx : liveAimX
            readonly property real ay: isNaN(liveAimY) ? (values.aimY || 0) * root.sy : liveAimY

            // Pointer to knob centre at the press, so the knob does not jump under the pointer.
            property point grab: Qt.point(0, 0)

            function clearLive() {
                liveX = NaN
                liveY = NaN
                liveAimX = NaN
                liveAimY = NaN
            }

            Rectangle {
                visible: handle.values.spot === true
                width: 14
                height: 14
                radius: 7
                x: handle.ax - width / 2
                y: handle.ay - height / 2
                color: "transparent"
                border.width: 2
                border.color: aimArea.containsMouse || aimArea.pressed
                              ? Theme.primary : (handle.values.color || "#ffffff")

                MouseArea {
                    id: aimArea
                    anchors.fill: parent
                    anchors.margins: -Theme.spacingSm
                    hoverEnabled: true
                    cursorShape: Qt.CrossCursor
                    preventStealing: true

                    onPressed: {
                        root.interacting = true
                        EditorState.beginPreviewDrag(qsTr("Aim light"))
                    }
                    onPositionChanged: (mouse) => {
                        if (!pressed)
                            return
                        const p = aimArea.mapToItem(root, mouse.x, mouse.y)
                        const aim = EditorState.preview.aimDepthLight3d(handle.modelData.effect,
                                                                        p.x / root.sx, p.y / root.sy)
                        if (aim.aimX === undefined)
                            return
                        handle.liveAimX = p.x
                        handle.liveAimY = p.y
                        root.writeParam(handle.prefix + "aimX", aim.aimX)
                        root.writeParam(handle.prefix + "aimY", aim.aimY)
                    }
                    onReleased: { handle.clearLive(); root.endInteraction() }
                    onCanceled: { handle.clearLive(); root.endInteraction() }
                }
            }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                x: handle.hx - width / 2
                y: handle.hy - height / 2
                color: handle.values.color || "#ffffff"
                border.width: 2
                border.color: lightArea.containsMouse || lightArea.pressed
                              ? Theme.primary : Theme.primaryForeground

                Text {
                    anchors.centerIn: parent
                    text: handle.modelData.light || ""
                    // Dark on the light's own colour: every default is a pale tint.
                    color: "#1a1a1a"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: lightArea
                    anchors.fill: parent
                    anchors.margins: -Theme.spacingSm
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    preventStealing: true

                    onPressed: (mouse) => {
                        const p = lightArea.mapToItem(root, mouse.x, mouse.y)
                        handle.grab = Qt.point(handle.hx - p.x, handle.hy - p.y)
                        root.interacting = true
                        EditorState.beginPreviewDrag(qsTr("Move light"))
                    }
                    onPositionChanged: (mouse) => {
                        if (!pressed)
                            return
                        const p = lightArea.mapToItem(root, mouse.x, mouse.y)
                        const x = p.x + handle.grab.x
                        const y = p.y + handle.grab.y
                        const moved = EditorState.preview.moveDepthLight3d(handle.modelData.effect,
                                                                           handle.modelData.light,
                                                                           x / root.sx, y / root.sy)
                        if (moved.x === undefined)
                            return
                        handle.liveX = x
                        handle.liveY = y
                        root.writeParam(handle.prefix + "x", moved.x)
                        root.writeParam(handle.prefix + "y", moved.y)
                        root.writeParam(handle.prefix + "z", moved.z)
                    }
                    onReleased: { handle.clearLive(); root.endInteraction() }
                    onCanceled: { handle.clearLive(); root.endInteraction() }

                    // Scrolling up brings the light towards the viewer; Shift for fine steps.
                    onWheel: (wheel) => {
                        const step = (wheel.modifiers & Qt.ShiftModifier) !== 0 ? 0.01 : 0.05
                        const z = Math.max(handle.values.zMin, Math.min(handle.values.zMax,
                                           (handle.values.z || 0) - Math.sign(wheel.angleDelta.y) * step))
                        EditorState.beginPreviewDrag(qsTr("Move light"))
                        root.writeParam(handle.prefix + "z", z)
                        EditorState.commitPreviewDrag()
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
