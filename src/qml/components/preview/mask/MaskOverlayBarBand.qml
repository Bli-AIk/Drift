import QtQuick
import Drift

// One of the two full-width bars bands.
Rectangle {
    id: band

    required property bool selected

    anchors.fill: parent
    color: "transparent"
    border.width: Theme.c.maskOverlayBarBand.borderWidth
    border.color: band.selected ? Theme.c.maskOverlayBarBand.borderSelected : Theme.c.maskOverlayBarBand.border
    opacity: band.selected ? 1.0 : Theme.c.maskOverlayBarBand.opacity
}
