import QtQuick
import Drift

// One of the two full-width bars bands.
Rectangle {
    id: band

    required property bool selected

    anchors.fill: parent
    color: "transparent"
    border.width: Theme.borderWidth
    border.color: band.selected ? Theme.primary : Theme.mutedForeground
    opacity: band.selected ? 1.0 : 0.5
}
