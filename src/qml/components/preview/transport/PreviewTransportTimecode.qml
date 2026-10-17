import QtQuick
import QtQuick.Layouts
import Drift
// Current time / total, with the project frame rate in the tooltip.
Row {
    id: timecode

    required property int projectFps
    required property real currentSeconds
    required property real durationSeconds
    required property var formatTimecode

    Layout.alignment: Qt.AlignVCenter
    spacing: 0

    HoverHandler { id: timecodeHover }

    ThemedToolTip {
        text: qsTr("Current time / total · %1 frames per second").arg(timecode.projectFps)
        visible: timecodeHover.hovered
    }

    Text {
        text: timecode.formatTimecode(timecode.currentSeconds)
        color: Theme.c.previewTransportTimecode.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        text: " / "
        color: Theme.c.previewTransportTimecode.foregroundMuted
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        text: timecode.formatTimecode(timecode.durationSeconds)
        color: Theme.c.previewTransportTimecode.foregroundMuted
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
    }
}
