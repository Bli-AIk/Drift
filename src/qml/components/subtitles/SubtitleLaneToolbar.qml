import QtQuick
import Drift

Item {
    id: root

    property bool follow: true
    property bool canDelete: false
    property int cueCount: 0

    signal zoomOut()
    signal zoomIn()
    signal fitAll()
    signal followToggled()
    signal addCue()
    signal deleteSelected()

    implicitHeight: Theme.controlHeight + Theme.spacingMd * 2

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.c.panelFrame.borderWidth
        color: Theme.c.keyframesToolbar.border
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs

        IconButton {
            glyph: Theme.icons.zoomOut
            tooltip: qsTr("Zoom out")
            onClicked: root.zoomOut()
        }

        IconButton {
            glyph: Theme.icons.zoomFit
            tooltip: qsTr("Fit the clip in view")
            onClicked: root.fitAll()
        }

        IconButton {
            glyph: Theme.icons.zoomIn
            tooltip: qsTr("Zoom in")
            onClicked: root.zoomIn()
        }

        ThemedToggleButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.locateFixed
            checked: root.follow
            tooltip: qsTr("Keep the playhead in view during playback")
            onClicked: root.followToggled()
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.c.panelFrame.borderWidth
            height: Theme.controlHeightSm
            color: Theme.c.keyframesToolbar.separator
        }

        IconButton {
            glyph: Theme.icons.plus
            tooltip: qsTr("Add a cue at the playhead")
            onClicked: root.addCue()
        }

        IconButton {
            glyph: Theme.icons.trash
            enabled: root.canDelete
            tooltip: qsTr("Delete the selected cues (Delete)")
            onClicked: root.deleteSelected()
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: Theme.spacingMd
            text: qsTr("%n cue(s)", "", root.cueCount)
            color: Theme.c.subtitleLane.foregroundMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }
    }
}
