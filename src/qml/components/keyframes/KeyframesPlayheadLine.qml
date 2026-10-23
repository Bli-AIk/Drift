import QtQuick
import Drift

Rectangle {
    required property var timeView

    readonly property real centerX: timeView.xFor(EditorState.playheadSeconds)

    visible: centerX >= 0 && centerX <= parent.width
    x: centerX - width / 2
    width: Theme.playheadLineWidth
    height: parent.height
    color: Theme.c.timelinePlayheadLine.foreground
}
