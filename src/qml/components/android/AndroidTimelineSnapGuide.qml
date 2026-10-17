import QtQuick
import Drift

// The vertical the playhead or a trim snapped to, with the time it landed on.
Rectangle {
    id: guide

    property real snapSeconds: -1
    property real pxPerSecond: 1
    property real seekHeaderHeight: 0
    property real tracksHeight: 0
    property var formatTime: function(seconds) { return "" }

    visible: opacity > 0
    opacity: guide.snapSeconds >= 0 ? 1 : 0
    x: guide.snapSeconds * guide.pxPerSecond
    y: guide.seekHeaderHeight
    width: Theme.c.androidTimelineSnapGuide.borderWidth
    height: guide.tracksHeight
    color: Theme.c.androidTimelineSnapGuide.background
    z: 6

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingSm
        width: snapLabel.implicitWidth + Theme.spacingMd * 2
        height: snapLabel.implicitHeight + Theme.spacingSm
        radius: Theme.c.androidTimelineSnapGuide.radius
        color: Theme.c.androidTimelineSnapGuide.background

        Text {
            id: snapLabel
            anchors.centerIn: parent
            text: guide.formatTime(guide.snapSeconds)
            color: Theme.c.androidTimelineSnapGuide.foreground
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeTick
        }
    }
}
