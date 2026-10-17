import QtQuick
import Drift

// Drag to widen the header column; double-click restores the default.
MouseArea {
    property bool resizable: false
    id: widthHandle
    visible: resizable
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 6
    z: 50
    hoverEnabled: true
    cursorShape: Qt.SplitHCursor
    preventStealing: true
    onPositionChanged: (mouse) => {
        if (pressed)
            EditorState.preferences.trackLabelsWidth = x + mouse.x + width / 2
    }
    onDoubleClicked: EditorState.preferences.trackLabelsWidth = Theme.trackLabelsWidth

    Rectangle {
        anchors.right: parent.right
        width: 2
        height: parent.height
        color: Theme.primary
        opacity: widthHandle.pressed || widthHandle.containsMouse ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }
    }
}
