import QtQuick
import Drift

// Playhead tick on the timeline minimap.
Rectangle {
    property var host
    visible: host.width > 0
    x: EditorState.playheadSeconds * host.overviewPxPerSecond - width / 2
    y: 0
    width: 2
    height: parent.height
    color: Theme.destructive
}
