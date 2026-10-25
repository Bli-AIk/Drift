import QtQuick
import QtQuick.Controls.Basic
import Drift

// Anchored host for EasingPicker. Opens beside its anchor, flipping above it or
// clamping to the window so the picker never runs off-screen.
Popup {
    id: root

    property Item anchorItem: null
    property int trackIndex: -1
    property int clipIndex: -1
    property string propKey: ""
    property string propLabel: ""
    property real keySeconds: 0

    readonly property real pickerWidth: 272
    readonly property real edgeMargin: Theme.spacingLg

    parent: Overlay.overlay
    width: pickerWidth
    padding: Theme.spacingLg
    modal: false
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function openFor(track, clip, prop, seconds) {
        trackIndex = track
        clipIndex = clip
        propKey = prop
        keySeconds = seconds
        placeNearAnchor()
        open()
    }

    function placeNearAnchor() {
        const overlay = Overlay.overlay
        if (!overlay || !anchorItem)
            return
        const bottomLeft = anchorItem.mapToItem(overlay, 0, anchorItem.height + Theme.spacingXs)
        const topLeft = anchorItem.mapToItem(overlay, 0, -Theme.spacingXs)
        const right = bottomLeft.x + anchorItem.width
        const maxX = overlay.width - width - edgeMargin
        x = Math.max(edgeMargin, Math.min(maxX, right - width))
        const below = bottomLeft.y
        const fitsBelow = below + height <= overlay.height - edgeMargin
        y = fitsBelow ? below : Math.max(edgeMargin, topLeft.y - height)
    }

    onHeightChanged: {
        if (opened)
            placeNearAnchor()
    }

    background: Rectangle {
        color: Theme.c.easingPicker.background
        border.width: Theme.c.easingPicker.borderWidth
        border.color: Theme.c.easingPicker.border
        radius: Theme.c.easingPicker.radiusPopup
    }

    // Opacity plus scale, matching PropertyKeyframeRow's value popup.
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.durationBase
                easing.type: Theme.easing
            }
            NumberAnimation {
                property: "scale"
                from: 0.96
                to: 1.0
                duration: Theme.durationBase
                easing.type: Theme.easing
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Theme.durationFast
                easing.type: Theme.easing
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.96
                duration: Theme.durationFast
                easing.type: Theme.easing
            }
        }
    }

    contentItem: EasingPicker {
        width: root.pickerWidth - root.padding * 2
        trackIndex: root.trackIndex
        clipIndex: root.clipIndex
        propKey: root.propKey
        propLabel: root.propLabel
        keySeconds: root.keySeconds
        onCloseRequested: root.close()
    }
}
