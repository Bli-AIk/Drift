import QtQuick
import Drift

// One alignment guide spanning the overlay. alongX is the vertical line.
Rectangle {
    id: guide

    property real position: -1
    property bool alongX: true

    visible: guide.position >= 0
    x: guide.alongX ? guide.position : 0
    y: guide.alongX ? 0 : guide.position
    width: guide.alongX ? 1 : parent.width
    height: guide.alongX ? parent.height : 1
    color: Theme.c.transformOverlaySnapGuide.background
    z: 400
}
