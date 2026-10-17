import QtQuick
import Drift

// Doubles as the way back into a render whose progress sheet was dismissed:
// without it a running export is unreachable and uncancellable, there being no
// second window on a phone to leave it open in. The ring is drawn around the
// glyph rather than replacing it, so the pill keeps its width and its label
// while the render runs.
ThemedButton {
    id: exportPill

    property bool exportInProgress: false
    property real exportProgress: 0

    signal exportRequested()
    signal progressRequested()

    variant: "primary"
    glyph: Theme.icons.upload
    text: qsTr("Export")
    tooltip: exportPill.exportInProgress ? qsTr("Show export progress")
                                         : qsTr("Export")
    onClicked: exportPill.exportInProgress ? exportPill.progressRequested()
                                           : exportPill.exportRequested()

    CircularProgress {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingXl + Theme.iconSizeMd / 2 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        visible: exportPill.exportInProgress
        size: Theme.iconSizeXl
        strokeWidth: 2
        value: exportPill.exportProgress
    }
}
