import QtQuick
import Drift

// Landing preview outline for a library drop or a clip move.
Rectangle {
    property TimelinePanel panel
    property int trackIndex: -1
    visible: panel.dropTrackIndex === trackIndex
             && !panel.dropCreatesNewTrack
    x: panel.dropStartSeconds * panel.pxPerSecond
    width: panel.dropDurationSeconds * panel.pxPerSecond
    height: parent.height
    radius: Theme.radiusSm
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
    border.width: 2
    border.color: Theme.primary
    z: 5

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
