import QtQuick
import Drift

// One sequence in the timeline switcher menu.
ThemedMenuItem {
    property string sequenceId
    property string sequenceName

    text: sequenceName
    icon.name: EditorState.activeSequenceId === sequenceId
               ? Theme.icons.check
               : (sequenceId === "" ? Theme.icons.film : Theme.icons.layers)
    onTriggered: EditorState.openSequence(sequenceId)
}
