import QtQuick
import Drift

// Dims the filmstrip outside the kept range. `leading` is the part before in-point.
Rectangle {
    id: shade

    property bool leading: true
    required property real edge
    required property real span

    x: shade.leading ? 0 : shade.edge
    width: shade.leading ? shade.edge : Math.max(0, shade.span - shade.edge)
    height: parent.height
    color: Theme.scrimStrong
}
