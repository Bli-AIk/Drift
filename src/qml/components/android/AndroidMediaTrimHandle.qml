import QtQuick
import Drift

// Grabbable end of the trim range. The desktop hairline gave no hint that the
// range could be dragged; these are thumb-width and carry a grip.
Rectangle {
    id: handle

    required property var modelData
    required property var preview
    property real stripWidth: 1
    property real inX: 0
    property real outX: 0

    readonly property bool isIn: modelData.edge === "in"

    width: 22
    height: parent ? parent.height : 0
    x: handle.isIn ? handle.inX : handle.outX - width
    color: Theme.primary
    radius: Theme.radiusXs
    z: 3

    Column {
        anchors.centerIn: parent
        spacing: 3
        Repeater {
            model: 3
            Rectangle {
                width: 10
                height: 2
                radius: 1
                color: Theme.primaryForeground
                opacity: 0.9
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -12
        enabled: !handle.preview.saving
        preventStealing: true
        onPressed: {
            EditorState.assetPreview.pause()
            Haptics.pickUp()
        }
        onReleased: Haptics.drop()
        onCanceled: Haptics.drop()
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const t = ((parent.x + mouse.x + (parent.isIn ? 0 : parent.width))
                       / Math.max(1, handle.stripWidth)) * handle.preview.durationSeconds
            if (parent.isIn)
                handle.preview.inSeconds = t
            else
                handle.preview.outSeconds = t
            handle.preview.clampRange()
            handle.preview.seekTo(parent.isIn ? handle.preview.inSeconds
                                              : handle.preview.outSeconds)
        }
    }
}
