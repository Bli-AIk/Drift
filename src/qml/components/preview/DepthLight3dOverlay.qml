import QtQuick
import Drift

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

            DepthLight3dAimRing {
                source: handle
                overlay: root
            }

            DepthLight3dKnob {
                source: handle
                overlay: root
            }
        }
    }
}
