import QtQuick
import Drift
IconButton {
    id: button

    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.fastForward
    variant: "text"
    tooltip: Theme.platformShortcutText(qsTr("Jump forward 1s · Shift for 5s · Ctrl for 10s"))

    function jumpStep() {
        const modifiers = EditorState.keyboardModifiers()
        if (Theme.primaryModifierPressed(modifiers))
            return 10
        if (modifiers & Qt.ShiftModifier)
            return 5
        return 1
    }

    onClicked: EditorState.jumpSeconds(button.jumpStep())
}
