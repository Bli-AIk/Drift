import QtQuick
import Drift
// Jump amount comes from the modifiers held at click time rather than from a separate
// control: three amounts in each direction would be six more buttons in a row that has
// to stay centred. AbstractButton.clicked carries no modifiers, hence the query into Qt.
IconButton {
    id: button

    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.rewind
    variant: "text"
    tooltip: Theme.platformShortcutText(qsTr("Jump back 1s · Shift for 5s · Ctrl for 10s"))

    function jumpStep() {
        const modifiers = EditorState.keyboardModifiers()
        if (Theme.primaryModifierPressed(modifiers))
            return 10
        if (modifiers & Qt.ShiftModifier)
            return 5
        return 1
    }

    onClicked: EditorState.jumpSeconds(-button.jumpStep())
}
