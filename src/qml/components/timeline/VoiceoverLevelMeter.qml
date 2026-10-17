import QtQuick
import Drift

// Live voice level, green through amber to red.
Item {
    width: 44
    height: 12
    anchors.verticalCenter: parent.verticalCenter

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Qt.rgba(0, 0, 0, 0.4)
        border.color: Theme.panelBorder
        border.width: 1
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: Math.max(1, Math.min(parent.width - 2, (parent.width - 2) * EditorState.audioRecordLevel))
        radius: 1
        color: EditorState.audioRecordLevel > 0.85
               ? Theme.destructive
               : (EditorState.audioRecordLevel > 0.6 ? "#eab308" : "#22c55e")
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
