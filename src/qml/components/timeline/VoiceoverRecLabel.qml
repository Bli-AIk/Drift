import QtQuick
import Drift

// REC / PAUSED caption beside the record dot.
Text {
    property bool paused: false
    text: paused ? qsTr("PAUSED") : qsTr("REC")
    font.bold: true
    font.pixelSize: 11
    color: paused ? "#eab308" : Theme.destructive
    anchors.verticalCenter: parent.verticalCenter
}
