import QtQuick
import Drift

// The edge under the pointer, or the one being dragged.
Rectangle {
    id: mark

    // {axis, from, to} or null, plus where that edge sits.
    property var edge: null
    property real at: 0
    property bool removing: false

    visible: mark.edge !== null
    readonly property bool vertical: mark.edge ? mark.edge.axis === "x" : false
    x: !mark.edge ? 0 : vertical ? mark.at - 1 : mark.edge.from
    y: !mark.edge ? 0 : vertical ? mark.edge.from : mark.at - 1
    width: !mark.edge ? 0 : vertical ? Theme.c.guideEditHighlight.strokeWidth : mark.edge.to - mark.edge.from
    height: !mark.edge ? 0 : vertical ? mark.edge.to - mark.edge.from : Theme.c.guideEditHighlight.strokeWidth
    color: mark.removing ? Theme.c.guideEditHighlight.backgroundRemoving : Theme.c.guideEditHighlight.background
}
