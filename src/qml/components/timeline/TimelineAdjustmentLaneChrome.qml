import QtQuick
import Drift

// Tint and bottom hairline of one nested adjustment lane.
Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.clipEffect.r, Theme.clipEffect.g, Theme.clipEffect.b, 0.12)
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(0, 0, 0, 0.25)
    }
}
