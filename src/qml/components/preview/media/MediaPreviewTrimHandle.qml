import QtQuick
import Drift

// In or out handle on the filmstrip.
Rectangle {
    id: handle

    required property var modelData
    required property var editor
    required property var strip
    required property real inX
    required property real outX
    required property bool editing

    visible: handle.editor.canTrim
    width: Theme.touchUi ? 14 : 8
    height: parent.height
    x: (handle.modelData.edge === "in" ? handle.inX : handle.outX) - width / 2
    color: Theme.c.mediaPreviewTrimHandle.background
    z: 3

    MouseArea {
        anchors.fill: parent
        anchors.margins: Theme.touchUi ? -8 : -4
        enabled: handle.editing
        cursorShape: Qt.SizeHorCursor
        preventStealing: true
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const t = ((parent.x + width / 2 + mouse.x)
                       / Math.max(1, handle.strip.width)) * handle.editor.durationSeconds
            if (handle.modelData.edge === "in")
                handle.editor.inSeconds = t
            else
                handle.editor.outSeconds = t
            handle.editor.clampRange()
            handle.editor.seekTo(handle.modelData.edge === "in" ? handle.editor.inSeconds
                                                                : handle.editor.outSeconds)
        }
    }
}
