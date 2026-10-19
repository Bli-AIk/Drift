import QtQuick
import Drift

// Record dot, REC/PAUSED caption, and the running timer.
Row {
    id: status

    // The bar's own visible flag: the dot only blinks while the bar is on screen.
    property bool barVisible: false

    spacing: 6
    anchors.verticalCenter: parent.verticalCenter

    VoiceoverRecDot {
        paused: EditorState.isAudioRecordingPaused
        running: status.barVisible
    }
    VoiceoverRecLabel {
        paused: EditorState.isAudioRecordingPaused
    }
    VoiceoverTimerReadout { }
}
