import QtQuick
import QtQuick.Window
import Drift

// Opened for one clip; a window rather than a dialog so the timeline stays visible, matching
// SegmentationWindow. The body is shared with the Noise Removal panel.
ToolWindow {
    id: root

    width: 760
    height: 560
    minimumWidth: 560
    minimumHeight: 460
    title: qsTr("Remove noise")
    color: Theme.c.denoiseWindow.background

    function openFor(track, clip, durationSeconds) {
        view.openFor(track, clip, durationSeconds)
        root.show()
        root.raise()
        root.requestActivate()
    }

    // Backgrounding on Android pauses every transport. This window owns its own audition
    // player, which AndroidMain's application-state handler has no other route to; without
    // this the call threw and took the rest of that handler — the recovery flush included —
    // down with it.
    function stopPlayback() {
        view.stopPlayback()
    }

    onClosing: view.release()

    DenoiseView {
        id: view
        anchors.fill: parent
        onCancelRequested: root.close()
        onApplied: root.close()
    }
}
