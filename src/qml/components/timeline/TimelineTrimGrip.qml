import QtQuick
import Drift

// Grip notch: says "this edge moves" without a tooltip, which touch cannot show.
Rectangle {
    anchors.centerIn: parent
    width: 3
    height: Math.min(16, parent.height * 0.4)
    radius: Theme.c.timelineTrimGrip.radius
    color: Theme.c.timelineTrimGrip.foreground
    opacity: 0.9
}
