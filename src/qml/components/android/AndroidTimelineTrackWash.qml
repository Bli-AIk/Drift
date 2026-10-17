import QtQuick
import Drift

// A transform layer's row carries a faint wash of its colour.
Rectangle {
    id: wash

    property bool shown: false

    anchors.fill: parent
    visible: wash.shown
    color: Qt.rgba(Theme.c.androidTimelineTrackWash.background.r,
                   Theme.c.androidTimelineTrackWash.background.g,
                   Theme.c.androidTimelineTrackWash.background.b, 0.07)
}
