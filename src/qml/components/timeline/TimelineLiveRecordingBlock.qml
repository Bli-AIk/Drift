import QtQuick
import Drift

// Live voiceover recording block, waveform, and REC badge on a track.
Rectangle {
    property TimelinePanel panel
    property int trackIndex: -1
    id: liveRecordingBlock
    visible: EditorState.isRecordingAudio && EditorState.recordingTrackIndex === trackIndex
    x: (EditorState.playheadSeconds - EditorState.audioRecordSeconds) * panel.pxPerSecond
    width: Math.max(2, EditorState.audioRecordSeconds * panel.pxPerSecond)
    height: parent.height
    color: Qt.rgba(Theme.destructive.r, Theme.destructive.g, Theme.destructive.b, 0.25)
    border.color: EditorState.isAudioRecordingPaused ? "#eab308" : Theme.destructive
    border.width: 1
    radius: Theme.radiusSm
    clip: true
    z: 2

    // Real-time live audio waveform canvas
    // Capped and pinned to the newest end: the block grows with the
    // take, and a canvas as wide as a long recording at high zoom
    // would be a huge framebuffer. Draws only the peaks it covers.
    Canvas {
        id: liveWaveCanvas
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 1
        width: Math.min(Math.max(0, parent.width - 2), 4096)
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
            var full = Math.max(w, liveRecordingBlock.width - 2);
            var first = peaks.length * (full - w) / full;
            var n = peaks.length - first;

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
                var i0 = Math.floor(first + x * n / w);
                var i1 = Math.floor(first + (x + 1) * n / w);
                if (i1 <= i0) i1 = Math.min(peaks.length, i0 + 1);
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
                var j0 = Math.floor(first + xb * n / w);
                var j1 = Math.floor(first + (xb + 1) * n / w);
                if (j1 <= j0) j1 = Math.min(peaks.length, j0 + 1);
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
