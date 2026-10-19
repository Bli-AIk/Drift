import QtQuick
import Drift

Rectangle {
    property var host
    x: host.xForSeconds(EditorState.playheadSeconds) - Theme.playheadLineWidth / 2
    width: Theme.playheadLineWidth
    height: parent.height
    color: Theme.c.keyframeGraphPlayhead.accent
    z: 3
}
