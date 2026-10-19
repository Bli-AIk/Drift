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
                  ? Theme.c.transformOverlayBoxBorder.borderWidthSelected : Theme.c.transformOverlayBoxBorder.borderWidth
    border.color: boxBorder.selected ? (boxBorder.transformClip ? Theme.c.transformOverlayBoxBorder.borderSelectedTransform : Theme.c.transformOverlayBoxBorder.borderSelected)
                  : boxBorder.coveredBySelectedLayer ? Theme.c.transformOverlayBoxBorder.borderCovered
                  : hover.hovered ? Theme.c.transformOverlayBoxBorder.borderHover : "transparent"
    radius: Theme.c.transformOverlayBoxBorder.radius

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
