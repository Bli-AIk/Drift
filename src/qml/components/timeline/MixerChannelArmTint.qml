import QtQuick
import Drift

// Recording tint across a channel strip so an armed track reads from a distance.
Rectangle {
    property bool armed: false
    anchors.fill: parent
    visible: armed
    color: Qt.rgba(Theme.destructive.r, Theme.destructive.g, Theme.destructive.b, Theme.darkMode ? 0.08 : 0.05)
}
