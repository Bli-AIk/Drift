import QtQuick
import Drift

// Voiceover record button on an audio track header.
IconGlyph {
    id: micIcon

    property int trackIndex: -1
    property bool shown: false
    readonly property bool isRecordingHere:
        EditorState.isRecordingAudio && EditorState.recordingTrackIndex === trackIndex

    visible: shown
    glyph: Theme.icons.mic
    iconSize: 16
    anchors.verticalCenter: parent.verticalCenter
    iconColor: isRecordingHere
               ? (EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive)
               : (micMouse.containsMouse ? Theme.panelForeground : Theme.mutedForeground)

    Accessible.role: Accessible.Button
    Accessible.name: isRecordingHere ? qsTr("Stop recording") : qsTr("Record voiceover")

    ThemedToolTip {
        visible: micMouse.containsMouse
        text: micIcon.isRecordingHere
              ? (EditorState.isAudioRecordingPaused ? qsTr("Paused — click to finish recording") : qsTr("Recording — click to finish recording"))
              : qsTr("Record voiceover (mic)")
    }

    MouseArea {
        id: micMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (EditorState.isRecordingAudio)
                EditorState.stopAudioRecording()
            else
                EditorState.startAudioRecording(micIcon.trackIndex)
        }
    }

    SequentialAnimation on opacity {
        running: micIcon.isRecordingHere && !EditorState.isAudioRecordingPaused
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 450 }
        NumberAnimation { to: 1.0; duration: 450 }
    }
}
