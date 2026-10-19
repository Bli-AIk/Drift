import QtQuick
import Drift

// One microphone in the voiceover input menu.
ThemedMenuItem {
    required property var modelData
    text: modelData.name
    icon.name: modelData.name === EditorState.currentMicrophoneName ? Theme.icons.check : ""
    onTriggered: EditorState.selectMicrophone(modelData.id)
}
