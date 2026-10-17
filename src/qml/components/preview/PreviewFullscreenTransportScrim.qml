import QtQuick
import Drift

// In fullscreen the bar sits over the picture, so it needs a surface of its own.
Rectangle {
    id: scrim

    required property bool shown
    required property real plateOpacity

    visible: scrim.shown
    opacity: scrim.plateOpacity
    color: Qt.rgba(Theme.c.previewFullscreenTransportScrim.background.r, Theme.c.previewFullscreenTransportScrim.background.g, Theme.c.previewFullscreenTransportScrim.background.b, 0.9)
}
