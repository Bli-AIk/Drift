import QtQuick
import Drift

// Play/pause over the picture, where a phone player puts it. Fades out while
// the preview is actually playing.
Rectangle {
    id: badge

    property bool playing: false

    width: 64
    height: 64
    radius: width / 2
    color: Theme.scrimStrong
    opacity: badge.playing ? 0 : 1

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    IconGlyph {
        anchors.centerIn: parent
        glyph: Theme.icons.play
        iconSize: Theme.iconSizeLg
        iconColor: Theme.onMedia
    }
}
