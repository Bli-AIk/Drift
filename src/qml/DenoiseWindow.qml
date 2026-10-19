import QtQuick
import QtQuick.Window
import QtMultimedia
import Drift 1.0

// Audition surface for noise removal. Opened for one clip: a short window of it is run through the
// model, the original and the result are compared side by side, and only then is the whole clip
// rendered. A window rather than a dialog so the timeline stays visible, matching SegmentationWindow.
ToolWindow {
    id: root

    property int trackIndex: -1
    property int clipIndex: -1
    property real clipDurationSeconds: 0

    // Rendered snippets for the A/B. Empty until the first preview lands.
    property string originalPath: ""
    property string cleanPath: ""
    property bool showClean: true

    readonly property real previewSpan: 8
    readonly property bool hasPreview: originalPath !== "" && cleanPath !== ""

    width: 760
    height: 560
    minimumWidth: 560
    minimumHeight: 460
    title: qsTr("Remove noise")
    color: Theme.c.denoiseWindow.background

    function openFor(track, clip, durationSeconds) {
        root.trackIndex = track
        root.clipIndex = clip
        root.clipDurationSeconds = durationSeconds
        root.originalPath = ""
        root.cleanPath = ""
        root.showClean = true
        windowSlider.value = 0
        root.show()
        root.raise()
        root.requestActivate()
        EditorState.denoise.preview(track, clip, 0)
    }

    // Backgrounding on Android pauses every transport. This window owns its own audition
    // player, which AndroidMain's application-state handler has no other route to; without
    // this the call threw and took the rest of that handler — the recovery flush included —
    // down with it.
    function stopPlayback() {
        player.pause()
    }

    onClosing: {
        player.stop()
        if (EditorState.denoise.running)
            EditorState.denoise.cancel()
    }

    Connections {
        target: EditorState.denoise
        function onPreviewReady(originalPath, cleanPath) {
            player.stop()
            root.originalPath = originalPath
            root.cleanPath = cleanPath
        }
        function onFinished(ok, message) {
            if (ok)
                root.close()
        }
    }

    MediaPlayer {
        id: player
        audioOutput: AudioOutput {}
        // A bare absolute path in a url property would be resolved against this file's directory;
        // the snippets live in the app data cache, so they have to be spelled out as file: URLs.
        source: root.hasPreview
                ? Qt.resolvedUrl("file://" + (root.showClean ? root.cleanPath : root.originalPath))
                : ""
    }

    // Switching A/B mid-audition should land on the same moment in the other take, otherwise the
    // comparison is worthless.
    onShowCleanChanged: {
        if (!root.hasPreview)
            return
        const wasPlaying = player.playbackState === MediaPlayer.PlayingState
        const at = player.position
        player.stop()
        player.position = at
        if (wasPlaying)
            player.play()
    }

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingLg

        ThemedLabel {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("A short section of the clip is previewed here. Confirming runs the whole clip and adds the result as a new audio track above this one — the original is left untouched.")
        }

        // ----- Before / after --------------------------------------------------------------
        Column {
            width: parent.width
            spacing: Theme.spacingMd

            Repeater {
                model: [
                    { label: qsTr("Original"), path: root.originalPath, clean: false },
                    { label: qsTr("Noise removed"), path: root.cleanPath, clean: true }
                ]

                delegate: DenoiseWaveformLane {
                    width: content.width
                    showClean: root.showClean
                    hasPreview: root.hasPreview
                    sourcePlayer: player
                    onPicked: (clean) => { root.showClean = clean }
                }
            }
        }

        // ----- Transport + window position -------------------------------------------------
        Row {
            width: parent.width
            spacing: Theme.spacingMd

            ThemedButton {
                variant: "secondary"
                text: player.playbackState === MediaPlayer.PlayingState ? qsTr("Stop") : qsTr("Play")
                enabled: root.hasPreview
                onClicked: player.playbackState === MediaPlayer.PlayingState
                           ? player.stop() : player.play()
            }

            ThemedToggleButton {
                text: qsTr("Original")
                checked: !root.showClean
                enabled: root.hasPreview
                onClicked: root.showClean = false
            }

            ThemedToggleButton {
                text: qsTr("Noise removed")
                checked: root.showClean
                enabled: root.hasPreview
                onClicked: root.showClean = true
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacingMd
            visible: root.clipDurationSeconds > root.previewSpan

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Preview from")
            }

            ThemedSlider {
                id: windowSlider
                label: qsTr("Preview from")
                width: parent.width - 260
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: Math.max(0.001, root.clipDurationSeconds - root.previewSpan)
                enabled: !EditorState.denoise.running
                // Re-rendering on every tick would queue a model run per pixel of drag.
                onPressedChanged: {
                    if (!pressed)
                        EditorState.denoise.preview(root.trackIndex, root.clipIndex, value)
                }
            }

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                text: windowSlider.value.toFixed(1) + qsTr("s")
            }
        }

        // ----- Progress ---------------------------------------------------------------------
        Column {
            width: parent.width
            spacing: Theme.spacingSm
            visible: EditorState.denoise.running

            LabelledProgressRing {
                anchors.horizontalCenter: parent.horizontalCenter
                ringSize: 64
                value: EditorState.denoise.progress
                indeterminate: EditorState.denoise.progress <= 0
            }

            ThemedLabel {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: EditorState.denoise.status
            }

            ThemedButton {
                anchors.horizontalCenter: parent.horizontalCenter
                variant: "destructive"
                text: qsTr("Cancel")
                onClicked: EditorState.denoise.cancel()
            }
        }
    }

    // ----- Footer ---------------------------------------------------------------------------
    Row {
        id: footer
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        ThemedButton {
            variant: "ghost"
            text: qsTr("Cancel")
            onClicked: root.close()
        }

        ThemedButton {
            variant: "primary"
            text: qsTr("Remove noise")
            enabled: root.hasPreview && !EditorState.denoise.running
            onClicked: {
                player.stop()
                EditorState.denoise.apply(root.trackIndex, root.clipIndex)
            }
        }
    }
}
