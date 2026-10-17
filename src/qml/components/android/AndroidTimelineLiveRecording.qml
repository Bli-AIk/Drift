import QtQuick
import Drift

// Live voiceover recording indicator and waveform on this track.
Rectangle {
    id: liveRecordingBlock
    property int trackIndex: -1
    property real pxPerSecond: 1
    visible: EditorState.isRecordingAudio && EditorState.recordingTrackIndex === liveRecordingBlock.trackIndex
    x: (EditorState.playheadSeconds - EditorState.audioRecordSeconds) * liveRecordingBlock.pxPerSecond
    width: Math.max(2, EditorState.audioRecordSeconds * liveRecordingBlock.pxPerSecond)
    height: parent.height
    color: Qt.rgba(Theme.destructive.r, Theme.destructive.g, Theme.destructive.b, 0.25)
    border.color: EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive
    border.width: 1
    radius: Theme.radiusSm
    clip: true
    z: 2

    // Real-time live audio waveform canvas
    Canvas {
        id: liveWaveCanvas
        anchors.fill: parent
        anchors.margins: 1
        visible: parent.width > 4

        Connections {
            target: EditorState
            function onAudioRecordLivePeaksChanged() {
                liveWaveCanvas.requestPaint()
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var peaks = EditorState.audioRecordLivePeaks;
            if (!peaks || peaks.length === 0)
                return;

            var mid = height / 2;
            var half = mid * 0.85;
            var w = Math.max(1, Math.floor(width));
            var n = peaks.length;

            // Centerline guideline
            ctx.strokeStyle = Qt.rgba(1.0, 1.0, 1.0, 0.15);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(0, mid);
            ctx.lineTo(w, mid);
            ctx.stroke();

            // Mirrored waveform fill
            ctx.fillStyle = Qt.rgba(1.0, 1.0, 1.0, 0.85);
            ctx.beginPath();
            for (var x = 0; x < w; x++) {
                var i0 = Math.floor(x * n / w);
                var i1 = Math.floor((x + 1) * n / w);
                if (i1 <= i0) i1 = Math.min(n, i0 + 1);
                var peak = 0;
                for (var i = i0; i < i1; i++) {
                    if (peaks[i] > peak) peak = peaks[i];
                }
                var amp = Math.max(1.0, peak * half);
                if (x === 0) ctx.moveTo(x, mid - amp);
                else ctx.lineTo(x, mid - amp);
                ctx.lineTo(x + 1, mid - amp);
            }
            for (var xb = w - 1; xb >= 0; xb--) {
                var j0 = Math.floor(xb * n / w);
                var j1 = Math.floor((xb + 1) * n / w);
                if (j1 <= j0) j1 = Math.min(n, j0 + 1);
                var peakB = 0;
                for (var j = j0; j < j1; j++) {
                    if (peaks[j] > peakB) peakB = peaks[j];
                }
                var ampB = Math.max(1.0, peakB * half);
                ctx.lineTo(xb + 1, mid + ampB);
                ctx.lineTo(xb, mid + ampB);
            }
            ctx.closePath();
            ctx.fill();
        }
    }

    // Badge tag in upper-left corner of the recording clip
    Rectangle {
        visible: liveRecordingBlock.width > 55
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.top: parent.top
        anchors.topMargin: 3
        height: 18
        radius: 3
        color: Qt.rgba(0, 0, 0, 0.7)
        border.color: EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive
        border.width: 1
        width: liveRecRow.implicitWidth + 8

        Row {
            id: liveRecRow
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive
                anchors.verticalCenter: parent.verticalCenter
                SequentialAnimation on opacity {
                    running: liveRecordingBlock.visible && !EditorState.isAudioRecordingPaused
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 400 }
                    NumberAnimation { to: 1.0; duration: 400 }
                }
            }

            Text {
                text: (EditorState.isAudioRecordingPaused ? qsTr("PAUSED ") : qsTr("REC "))
                      + EditorState.audioRecordSeconds.toFixed(1) + "s"
                font.pixelSize: 10
                font.bold: true
                color: Theme.panelForeground
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
