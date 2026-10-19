import QtQuick
import Drift

SettingsSectionCard {
    title: qsTr("Playback")

    ThemedLabel {
        text: qsTr("Audio output")
    }

    ThemedComboBox {
        id: audioOutputCombo
        width: parent.width
        textRole: "label"
        valueRole: "id"
        model: EditorState.audioOutputDevices
        tooltip: qsTr("Where playback is heard. “System default” follows whatever your computer is set to, including when that changes.")
        currentIndex: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].id === EditorState.audioOutputDeviceId)
                    return i
            }
            return 0
        }
        onActivated: EditorState.audioOutputDeviceId = model[currentIndex].id
    }

    ThemedLabel {
        text: qsTr("Microphone input")
    }

    ThemedComboBox {
        id: audioInputCombo
        width: parent.width
        textRole: "name"
        valueRole: "id"
        model: EditorState.availableMicrophones
        tooltip: qsTr("Audio device used for recording voiceovers onto audio tracks.")
        currentIndex: {
            for (var i = 0; i < model.length; ++i) {
                if (model[i].name === EditorState.currentMicrophoneName)
                    return i
            }
            return 0
        }
        onActivated: EditorState.selectMicrophone(model[currentIndex].id)
    }
}
