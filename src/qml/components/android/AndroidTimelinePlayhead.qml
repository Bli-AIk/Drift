import QtQuick
import Drift

// Viewport-fixed playhead: a centre shaft and the wedge handle. Position and
// height are set by the timeline; this item only draws.
Item {
    Rectangle {
        anchors.left: parent.left
        y: Theme.timelineRulerHeight * 0.55
        width: parent.width
        height: parent.height - y
        color: Theme.primary
    }

    Item {
        width: Theme.playheadHandleSize
        height: Theme.playheadHandleSize + 2
        x: -width / 2 + parent.width / 2
        y: 3

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: parent.height * 0.55
            radius: 2
            color: Theme.primary
        }

        Canvas {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.4
            width: parent.width
            height: parent.height * 0.6
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(width, 0)
                ctx.lineTo(width * 0.5, height)
                ctx.closePath()
                ctx.fillStyle = Theme.primary
                ctx.fill()
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }
    }
}
