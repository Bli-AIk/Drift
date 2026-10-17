import QtQuick
import QtMultimedia
import Drift

Column {
    property bool showClean
    property bool hasPreview
    property MediaPlayer sourcePlayer
    signal picked(bool clean)
    id: lane
    required property var modelData
    spacing: Theme.spacingSm

    Row {
        width: parent.width
        spacing: Theme.spacingMd

        ThemedLabel {
            text: lane.modelData.label
            tone: showClean === lane.modelData.clean ? "default" : "muted"
        }

        ThemedLabel {
            visible: showClean === lane.modelData.clean && hasPreview
            tone: "muted"
            size: "sm"
            text: qsTr("· playing")
        }
    }

    Rectangle {
        width: parent.width
        height: 80
        radius: Theme.radiusMd
        color: Theme.panelBackground
        border.width: Theme.borderWidth
        border.color: showClean === lane.modelData.clean
                      ? Theme.panelSecondaryForeground : Theme.panelBorder

        SkeletonBox {
            anchors.fill: parent
            anchors.margins: Theme.spacingSm
            visible: !lane.modelData.path
        }

        Canvas {
            id: wave
            anchors.fill: parent
            anchors.margins: Theme.spacingSm
            visible: !!lane.modelData.path

            property var peaks: lane.modelData.path
                                ? EditorState.waveformPeaks(lane.modelData.path) : []

            onPeaksChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            // Peaks are computed off-thread, so the first read usually comes back
            // empty and arrives on this signal instead.
            Connections {
                target: EditorState
                function onWaveformReady(path) {
                    if (path === lane.modelData.path)
                        wave.peaks = EditorState.waveformPeaks(path)
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (!peaks || peaks.length === 0)
                    return;
                ctx.fillStyle = Theme.panelWaveformColor;
                var mid = height / 2;
                var w = Math.max(1, Math.floor(width));
                var n = peaks.length;
                for (var x = 0; x < w; x++) {
                    var i0 = Math.floor(x * n / w);
                    var i1 = Math.floor((x + 1) * n / w);
                    if (i1 <= i0)
                        i1 = Math.min(n, i0 + 1);
                    var peak = 0;
                    for (var i = i0; i < i1; i++) {
                        if (peaks[i] > peak)
                            peak = peaks[i];
                    }
                    var amp = peak * mid * 0.9;
                    if (amp > 0.5)
                        ctx.fillRect(x, mid - amp, 1, amp * 2);
                }
            }
        }

        // Playhead over whichever take is being auditioned.
        Rectangle {
            visible: showClean === lane.modelData.clean
                     && sourcePlayer.duration > 0
                     && sourcePlayer.playbackState !== MediaPlayer.StoppedState
            width: 1
            color: Theme.panelSecondaryForeground
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            x: sourcePlayer.duration > 0
               ? (sourcePlayer.position / sourcePlayer.duration) * parent.width : 0
        }

        MouseArea {
            anchors.fill: parent
            enabled: hasPreview
            onClicked: lane.picked(lane.modelData.clean)
        }
    }
}
