import QtQuick
import Drift
IconButton {
    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.repeat
    variant: "text"
    tooltip: EditorState.loopWorkAreaEnabled
             ? qsTr("Loop work area on — click to turn off")
             : qsTr("Loop work area off — click to turn on")
    active: EditorState.loopWorkAreaEnabled
    enabled: EditorState.workAreaActive
    onClicked: EditorState.toggleLoopWorkArea()
}
