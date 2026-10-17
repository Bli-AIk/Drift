import QtQuick
import Drift

// The clip's own bounds, so it is obvious what the mask coordinates are relative to.
Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.width: Theme.borderWidth
    border.color: Theme.mutedForeground
    opacity: 0.35
}
