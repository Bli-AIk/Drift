import QtQuick
import Drift

// The clip's on-canvas frame. Selected clips take the focus border; a clip
// covered by the selected transform layer is drawn in that layer's colour.
Rectangle {
    id: outline

    property bool selected: false
    property bool transformLayer: false
    property bool coveredBySelectedLayer: false

    anchors.fill: parent
    color: "transparent"
    border.width: outline.selected
                  ? Theme.borderWidthFocus : Theme.borderWidth
    border.color: outline.selected ? (outline.transformLayer ? Theme.clipTransform : Theme.primary)
                  : outline.coveredBySelectedLayer ? Theme.clipTransform : Theme.guideStrong
    radius: Theme.radiusXs

    Behavior on border.width {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
}
