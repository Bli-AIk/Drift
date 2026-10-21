import QtQuick
import Drift
IconButton {
    id: button

    property string shortcutTip: ""

    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.skipForward
    variant: "text"
    tooltip: button.shortcutTip
    onClicked: EditorState.triggerAction("goToEnd")
}
