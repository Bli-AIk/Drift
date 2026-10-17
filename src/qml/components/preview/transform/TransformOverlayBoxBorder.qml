import QtQuick
import Drift

// The clip box outline: selection, the transform-layer colour, and hover.
Rectangle {
    id: boxBorder

    required property bool selected
    required property bool transformClip
    required property bool coveredBySelectedLayer

    anchors.fill: parent
    color: "transparent"
    border.width: boxBorder.selected
                  ? Theme.borderWidthFocus : Theme.borderWidth
    border.color: boxBorder.selected ? (boxBorder.transformClip ? Theme.clipTransform : Theme.primary)
                  : boxBorder.coveredBySelectedLayer ? Theme.clipTransform
                  : hover.hovered ? Theme.guideStrong : "transparent"
    radius: Theme.radiusXs

    HoverHandler {
        id: hover
    }

    Behavior on border.width {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
    Behavior on border.color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
}
