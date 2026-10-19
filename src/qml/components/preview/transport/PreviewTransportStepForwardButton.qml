import QtQuick
import Drift
IconButton {
    id: button

    property string shortcutTip: ""

    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.stepForward
    variant: "text"
    tooltip: button.shortcutTip
    onClicked: EditorState.stepFrames(1)
}
