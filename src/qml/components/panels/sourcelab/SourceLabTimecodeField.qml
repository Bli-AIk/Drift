import QtQuick
import Drift
import "SourceLabTime.js" as SourceLabTime

// HH:MM:SS:FF at the source frame rate. Type a timecode or seconds to jump there, or +12 / -1:00
// to move from the playhead.
ThemedTextField {
    id: root

    property real seconds: 0
    property real fps: 30
    property real duration: 0

    signal seekRequested(real seconds)

    readonly property string shown: SourceLabTime.format(root.seconds, root.fps)

    text: root.shown
    horizontalAlignment: TextInput.AlignHCenter
    font.pixelSize: Theme.fontSizeBase
    implicitWidth: 132
    inputMethodHints: Qt.ImhNoPredictiveText

    onShownChanged: {
        if (!root.activeFocus)
            root.text = root.shown
    }

    onAccepted: {
        const target = SourceLabTime.parse(root.text, root.fps, root.seconds)
        if (!isNaN(target))
            root.seekRequested(Math.max(0, Math.min(root.duration, target)))
        root.text = root.shown
        root.focus = false
    }
    onActiveFocusChanged: {
        if (root.activeFocus)
            root.selectAll()
        else
            root.text = root.shown
    }

    Keys.onEscapePressed: {
        root.text = root.shown
        root.focus = false
    }
}
