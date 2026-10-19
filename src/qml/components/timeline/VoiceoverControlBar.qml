import QtQuick
import Drift

// Dedicated voiceover recording control bar displayed on the right side of the timeline
// when recording is active. Provides live time readout, microphone device selection,
// input voice gain adjustment, live stereo VU meter, pause/resume, done and cancel controls.
Rectangle {
    id: root

    implicitHeight: 34
    implicitWidth: mainRow.implicitWidth + 20
    radius: Theme.c.voiceoverControlBar.radius
    color: Qt.rgba(Theme.c.voiceoverControlBar.background.r, Theme.c.voiceoverControlBar.background.g, Theme.c.voiceoverControlBar.background.b, 0.96)
    border.color: EditorState.isAudioRecordingPaused ? Theme.c.voiceoverControlBar.borderPaused : Theme.c.voiceoverControlBar.border
    border.width: Theme.c.voiceoverControlBar.borderWidth

    VoiceoverGlow {
        paused: EditorState.isAudioRecordingPaused
        barRadius: root.radius
    }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 8

        VoiceoverStatus {
            barVisible: root.visible
        }
        VoiceoverBarDivider { }
        VoiceoverMicPicker { }
        VoiceoverBarDivider { }
        VoiceoverGainControl { }
        VoiceoverBarDivider { }
        VoiceoverLevelMeter { }
        VoiceoverBarDivider { }
        VoiceoverTransport { }
    }
}
