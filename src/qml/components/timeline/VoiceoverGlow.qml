import QtQuick

// Soft border glow behind the voiceover bar.
Rectangle {
    property bool paused: false
    property real barRadius: 0
    anchors.fill: parent
    anchors.margins: -1
    radius: barRadius + 1
    color: "transparent"
    border.color: paused ? Qt.rgba(0.9, 0.7, 0, 0.25) : Qt.rgba(0.9, 0.1, 0.1, 0.25)
    border.width: 1
    z: -1
}
