import QtQuick
import Drift

// One alignment guide. Drawn at the overlay root so it spans the canvas,
// not just the clip box. `guide` is in overlay px, or -1 when nothing is snapped.
Rectangle {
    id: line

    property real guide: -1
    property bool vertical: true

    visible: line.guide >= 0
    x: line.vertical ? line.guide : 0
    y: line.vertical ? 0 : line.guide
    width: line.vertical ? 1 : (parent ? parent.width : 0)
    height: line.vertical ? (parent ? parent.height : 0) : 1
    color: Theme.primary
    z: 400
}
