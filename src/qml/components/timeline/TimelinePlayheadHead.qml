import QtQuick
import Drift

// CapCut/Premiere-style scrubber head in the seek strip.
Item {
    width: Theme.playheadHandleSize
    height: Theme.playheadHandleSize + 2
    x: -width / 2 + Theme.playheadLineWidth / 2
    y: 3

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: parent.height * 0.55
        radius: 2
        color: Theme.primary
    }

    TimelinePlayheadTip { }
}
