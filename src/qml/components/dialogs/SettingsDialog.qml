import QtQuick
import Drift

// Host for SettingsPane. Opened from the header's Settings menu ("More settings…")
// and from the phone's overflow menu; both used to reach a tab in the assets rail.
ThemedDialog {
    id: root

    title: qsTr("Settings")
    preferredWidth: 960
    acceptText: qsTr("Done")
    showReject: false
    // The sidebar and page list run edge to edge, so the dialog's inset would
    // otherwise show as a gutter around them.
    padding: 0

    // Fixed height so switching categories does not resize the dialog.
    function openPage(pageId) {
        pane.selectPage(pageId)
        open()
    }

    contentItem: SettingsPane {
        id: pane
        implicitWidth: root.preferredWidth
        implicitHeight: Math.min(680, root.availableContentHeight)
    }
}
