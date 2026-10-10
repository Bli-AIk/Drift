import QtQuick
import Drift

// Backgrounding handling shared by both Android shells. The shells differ only in where the
// denoise window lives, so that is handed in rather than looked up.
Item {
    id: root

    // The open DenoiseWindow, or null. It has its own audition player.
    property var denoiseWindow: null

    visible: false

    // Backgrounding the app leaves the audio sink and the composite timer running, which
    // keeps decoding video nobody can see and holds the audio focus. Android will kill the
    // process for it eventually; pausing is the honest response to losing the foreground.
    Connections {
        target: Qt.application
        enabled: root.enabled
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive)
                return
            if (EditorState.playing)
                EditorState.playback.pause()
            // The two audition players are separate transports with their own audio sinks and
            // decode timers; pausing only the main one left them playing to nobody.
            EditorState.speedCurve.pause()
            if (root.denoiseWindow)
                root.denoiseWindow.stopPlayback()
            // Losing the foreground is the last moment guaranteed to run: the OS can reclaim the
            // process from here without another callback, and aboutToQuit does not fire when it does.
            EditorState.projectFile.flushRecoverySnapshot()
            // Decoder buffers, GL targets and image caches are all rebuildable; holding them
            // while backgrounded is what gets the process killed instead of resumed. Only for a
            // real backgrounding though: Android reports Inactive for every SAF picker, share
            // sheet and permission dialog, and tearing all of that down on a tap of Import would
            // cost a full rebuild on the way back. A job still running needs its decoders.
            if (Qt.application.state === Qt.ApplicationSuspended
                    || Qt.application.state === Qt.ApplicationHidden) {
                if (!EditorState.exportInProgress && !EditorState.projectFile.packaging)
                    EditorState.releaseTransientCaches()
            }
        }
    }
}
