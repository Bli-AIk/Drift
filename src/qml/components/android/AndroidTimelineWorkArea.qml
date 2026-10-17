import QtQuick
import Drift

// The in/out range painted down the tracks, plus the two edge rules.
Item {
    id: workAreaOverlay

    property real pxPerSecond: 1
    property real seekHeaderHeight: 0
    property real tracksHeight: 0
    property real viewHeight: 0

    z: 1
    y: workAreaOverlay.seekHeaderHeight
    width: parent ? parent.width : 0
    height: Math.max(workAreaOverlay.tracksHeight + Theme.trackGap,
                     workAreaOverlay.viewHeight - workAreaOverlay.seekHeaderHeight)

    readonly property real inX: EditorState.workAreaInSeconds >= 0
                               ? EditorState.workAreaInSeconds * workAreaOverlay.pxPerSecond
                               : -1
    readonly property real outX: EditorState.workAreaOutSeconds >= 0
                                ? EditorState.workAreaOutSeconds * workAreaOverlay.pxPerSecond
                                : -1

    Rectangle {
        visible: EditorState.workAreaActive
        x: parent.inX
        width: Math.max(0, parent.outX - parent.inX)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
    }

    Rectangle {
        visible: EditorState.workAreaInSeconds >= 0
        x: parent.inX
        width: 2
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Theme.primary
        opacity: 0.85
    }

    Rectangle {
        visible: EditorState.workAreaOutSeconds >= 0
        x: parent.outX - width
        width: 2
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: Theme.primary
        opacity: 0.85
    }
}
