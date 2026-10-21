import QtQuick
import QtQuick.Controls.Basic
import Drift

PanelFrame {
    id: root

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Recorder")
    }

    EmptyState {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        visible: !EditorState.isRecordingAudio
        glyph: Theme.icons.mic
        title: qsTr("Record a voiceover from your microphone onto an audio track")
        actionText: qsTr("Start recording")
        onActionTriggered: EditorState.startAudioRecording()
    }

    Flickable {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: EditorState.isRecordingAudio
        clip: true
        contentWidth: Math.max(width, voiceover.implicitWidth)
        contentHeight: height
        ScrollBar.horizontal: AppScrollBar { policy: ScrollBar.AsNeeded }

        VoiceoverControlBar {
            id: voiceover
            anchors.centerIn: parent
        }
    }
}
