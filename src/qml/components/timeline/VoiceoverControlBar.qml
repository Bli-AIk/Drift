import QtQuick
import Drift

// Dedicated voiceover recording control bar displayed on the right side of the timeline
// when recording is active. Provides live time readout, microphone device selection,
// input voice gain adjustment, live stereo VU meter, pause/resume, done and cancel controls.
Rectangle {
    id: root

    implicitHeight: 34
    implicitWidth: mainRow.implicitWidth + 20
    radius: Theme.radiusSm
    color: Qt.rgba(Theme.panelBackground.r, Theme.panelBackground.g, Theme.panelBackground.b, 0.96)
    border.color: EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive
    border.width: 1

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
