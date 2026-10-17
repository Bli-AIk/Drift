import QtQuick
import Drift

// Grip notch: says "this edge moves" without a tooltip, which touch cannot show.
Rectangle {
    anchors.centerIn: parent
    width: 3
    height: Math.min(16, parent.height * 0.4)
    radius: 1.5
    color: Theme.onMedia
    opacity: 0.9
}
