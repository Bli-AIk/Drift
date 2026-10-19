import QtQuick
import Drift

// Pause/resume, finish, and discard while a voiceover is recording.
Row {
    spacing: 2
    anchors.verticalCenter: parent.verticalCenter

    VoiceoverTransportButton {
        glyph: EditorState.isAudioRecordingPaused ? Theme.icons.play : Theme.icons.pause
        tooltip: EditorState.isAudioRecordingPaused ? qsTr("Resume recording") : qsTr("Pause recording")
        active: EditorState.isAudioRecordingPaused
        onClicked: EditorState.toggleAudioRecordingPause()
    }

    VoiceoverTransportButton {
        glyph: Theme.icons.check
        tooltip: qsTr("Done — finish recording and save to track")
        onClicked: EditorState.stopAudioRecording()
    }

    VoiceoverTransportButton {
        glyph: Theme.icons.trash
        tooltip: qsTr("Cancel — discard recording")
        onClicked: EditorState.cancelAudioRecording()
    }
}
