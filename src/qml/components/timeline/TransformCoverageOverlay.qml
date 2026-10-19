import QtQuick
import Drift
// While a transform clip is selected, tints the rows it moves over the time it is live, so the
// span reads on the timeline itself and not only in the header bracket. Takes no input.
Item {
    id: root

    property var tracks: []
    property real pxPerSecond: 1
    // function(index) -> row top / height, in this item's coordinates.
    property var rowTop: null
    property var rowHeight: null
    // A track being reordered: its tint would hang in the old place, so it hides meanwhile.
    property int draggingTrack: -1

    enabled: false

    readonly property int layerIndex: {
        const t = EditorState.selectedTrack
        return t >= 0 && t < tracks.length && tracks[t].isTransformLayer ? t : -1
    }
    readonly property var layerClip: {
        if (layerIndex < 0)
            return null
        const clips = tracks[layerIndex].clips || []
        const c = EditorState.selectedClip
        return c >= 0 && c < clips.length ? clips[c] : null
    }
    readonly property var covered: {
        const dep = tracks.length
        return layerClip ? (EditorState.transformLayerCoverage(layerIndex).covers || []) : []
    }

    visible: layerClip !== null && draggingTrack !== layerIndex
    opacity: visible ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Repeater {
        model: root.covered
        delegate: TransformCoverageTint {
            overlay: root
        }
    }
}
