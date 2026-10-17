import QtQuick
import Drift

// Hover tint on an empty gap between clips.
Rectangle {
    property bool hovered: false
    anchors.fill: parent
    visible: hovered
    color: Qt.rgba(Theme.panelAccent.r, Theme.panelAccent.g,
                   Theme.panelAccent.b, 0.35)
}
