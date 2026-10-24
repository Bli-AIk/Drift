import QtQuick
import Drift

// Transitions Section
Column {
    required property var dialog
    width: parent.width
    spacing: Theme.spacingSm
    visible: (dialog.clipAttrs.transitionCount || 0) > 0

    ThemedLabel {
        text: qsTr("Transitions")
        size: "xs"
        color: Theme.c.pasteAttributesTransitionsSection.foreground
        font.weight: Font.DemiBold
    }

    ThemedCheckBox {
        width: parent.width
        text: qsTr("Transitions (%n transition(s))", "", dialog.clipAttrs.transitionCount || 0)
        checked: dialog.pasteTransitions
        onToggled: dialog.pasteTransitions = checked
    }
}
