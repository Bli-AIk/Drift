import QtQuick
import Drift

Rectangle {
    id: root
    property var host
    readonly property bool dragging: resizeDrag.active
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 5
    z: 100
    color: resizeHover.hovered || resizeDrag.active ? Theme.c.keyframeGraphResizeGrip.backgroundActive : "transparent"
    opacity: Theme.c.keyframeGraphResizeGrip.opacity

    HoverHandler {
        id: resizeHover
        cursorShape: Qt.SizeVerCursor
    }
    TapHandler {
        onDoubleTapped: host.toggleExpanded()
    }
    DragHandler {
        id: resizeDrag
        target: null
        yAxis.enabled: true
        xAxis.enabled: false
        property real startHeight: 0
        onActiveChanged: {
            if (active)
                startHeight = host.laneHeight
        }
        onTranslationChanged: {
            if (!active)
                return
            host.laneHeight = Math.max(host.minLaneHeight,
                                       Math.min(host.maxLaneHeight,
                                                startHeight + translation.y))
        }
    }
}
