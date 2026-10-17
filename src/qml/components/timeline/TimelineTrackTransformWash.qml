import QtQuick
import Drift

// Faint wash on a transform layer's row.
Rectangle {
    property TimelinePanel panel
    property int trackIndex: -1
    anchors.fill: parent
    visible: panel.tracks[trackIndex].isTransformLayer === true
    color: Qt.rgba(Theme.clipTransform.r, Theme.clipTransform.g,
                   Theme.clipTransform.b, 0.07)
}
