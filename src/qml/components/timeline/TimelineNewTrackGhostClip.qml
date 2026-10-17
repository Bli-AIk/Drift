import QtQuick
import Drift

// Clip that would land in the ghost lane, including the importing hold.
Rectangle {
    property TimelinePanel panel
    x: panel.dropStartSeconds * panel.pxPerSecond
    width: Math.max(2, panel.dropDurationSeconds * panel.pxPerSecond)
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.margins: 2
    radius: Theme.radiusSm
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3)
    border.width: 2
    border.color: Theme.primary

    // The outline is held on screen after a file drop for as
    // long as the import it started is still probing, so it has
    // to say why it is sitting there empty.
    Text {
        anchors.centerIn: parent
        visible: panel.importDropPending
        text: qsTr("Importing…")
        color: Theme.primary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeTiny
        font.weight: Font.Medium

        SequentialAnimation on opacity {
            running: panel.importDropPending
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: Theme.durationSlow; easing.type: Theme.easing }
            NumberAnimation { to: 1.0; duration: Theme.durationSlow; easing.type: Theme.easing }
        }
    }
}
