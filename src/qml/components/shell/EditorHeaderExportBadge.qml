import QtQuick
import Drift

Rectangle {
    id: exportProgressBadge
    property bool dismissed: false
    signal reopenRequested()
    width: Theme.iconButtonSize
    height: Theme.iconButtonSize
    radius: width / 2
    color: badgeMouse.containsMouse ? Theme.popoverHover : "transparent"
    anchors.verticalCenter: parent.verticalCenter
    visible: opacity > 0
    opacity: EditorState.exportInProgress && dismissed ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
    }

    CircularProgress {
        anchors.centerIn: parent
        size: Theme.iconSizeXl
        strokeWidth: 3
        value: EditorState.exportProgress
    }

    ThemedToolTip {
        visible: badgeMouse.containsMouse
        text: qsTr("Export in progress (%1%) — click to view").arg(Math.round(EditorState.exportProgress * 100))
    }

    MouseArea {
        id: badgeMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: exportProgressBadge.reopenRequested()
    }
}
