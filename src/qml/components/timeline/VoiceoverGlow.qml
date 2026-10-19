import QtQuick
import Drift

// Soft border glow behind the voiceover bar.
Rectangle {
    property bool paused: false
    property real barRadius: 0
    anchors.fill: parent
    anchors.margins: -1
    radius: barRadius + 1
    color: "transparent"
    border.color: paused ? Theme.c.voiceoverGlow.borderPaused : Theme.c.voiceoverGlow.border
    border.width: Theme.c.voiceoverGlow.borderWidth
    z: -1
}
