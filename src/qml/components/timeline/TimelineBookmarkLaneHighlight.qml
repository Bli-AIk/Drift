import QtQuick
import Drift

// Work area highlight in the bookmark lane (between In/Out markers).
Rectangle {
    property real pxPerSecond: 1

    visible: EditorState.workAreaActive
    y: Theme.timelineRulerHeight
    height: Theme.timelineBookmarkRowHeight
    x: EditorState.workAreaInSeconds * pxPerSecond
    width: Math.max(0, (EditorState.workAreaOutSeconds - EditorState.workAreaInSeconds) * pxPerSecond)
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
    z: 1
}
