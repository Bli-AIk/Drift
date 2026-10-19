import QtQuick
import Drift

// REC / PAUSED caption beside the record dot.
Text {
    property bool paused: false
    text: paused ? qsTr("PAUSED") : qsTr("REC")
    font.bold: true
    font.pixelSize: 11
    color: paused ? Theme.c.voiceoverRecLabel.paused : Theme.c.voiceoverRecLabel.recording
    anchors.verticalCenter: parent.verticalCenter
}
