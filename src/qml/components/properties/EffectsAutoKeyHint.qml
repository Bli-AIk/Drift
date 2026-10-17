import QtQuick
import Drift

Column {
    property var inspector
    width: parent.width
    spacing: 10
    visible: inspector.selectedEffects.length > 0

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: qsTr("Move to a time, set a value, then click the diamond to add a keyframe. With Auto keyframes on, dragging a slider also creates them.")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    ThemedChip {
        text: qsTr("Auto keyframes")
        selected: EditorState.autoKeyEnabled
        onClicked: EditorState.autoKeyEnabled = !EditorState.autoKeyEnabled
    }
}
