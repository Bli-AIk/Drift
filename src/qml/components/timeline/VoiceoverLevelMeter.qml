import QtQuick
import Drift

// Live voice level, green through amber to red.
Item {
    width: 44
    height: 12
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        anchors.fill: parent
        radius: Theme.c.voiceoverLevelMeter.radius
        color: Theme.c.voiceoverLevelMeter.background
        border.color: Theme.c.voiceoverLevelMeter.border
        border.width: Theme.c.voiceoverLevelMeter.borderWidth
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: Math.max(1, Math.min(parent.width - 2, (parent.width - 2) * EditorState.audioRecordLevel))
        radius: Theme.c.voiceoverLevelMeter.levelRadius
        color: EditorState.audioRecordLevel > 0.85
               ? Theme.c.voiceoverLevelMeter.levelHot
               : (EditorState.audioRecordLevel > 0.6 ? Theme.c.voiceoverLevelMeter.levelWarm : Theme.c.voiceoverLevelMeter.level)
    }

    ThemedToolTip {
        text: qsTr("Live voice level: %1%").arg(Math.round(EditorState.audioRecordLevel * 100))
        visible: vuMouse.containsMouse
    }

    MouseArea {
        id: vuMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
