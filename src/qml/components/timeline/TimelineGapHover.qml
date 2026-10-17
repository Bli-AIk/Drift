import QtQuick
import Drift

// Hover tint on an empty gap between clips.
Rectangle {
    property bool hovered: false
    anchors.fill: parent
    visible: hovered
    color: Qt.rgba(Theme.c.timelineGapHover.background.r, Theme.c.timelineGapHover.background.g, Theme.c.timelineGapHover.background.b, 0.35)
}
