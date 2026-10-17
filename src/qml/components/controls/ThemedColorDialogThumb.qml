import QtQuick
import Drift

Rectangle {
    property color fill
    property bool active: false

    width: Theme.touchUi ? 24 : 16
    height: width
    radius: width / 2
    color: fill
    border.width: 2
    border.color: "white"
    scale: active ? 1.15 : 1

    Behavior on scale {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    // Outer hairline so the white ring still reads on white and pale colours.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.35)
    }
}
