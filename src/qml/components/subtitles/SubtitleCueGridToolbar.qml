import QtQuick
import Drift

Item {
    id: root

    property bool follow: true
    property bool timelineTimes: false
    property bool canInsertAfter: false
    property bool canDelete: false
    property int cueCount: 0
    property int selectedCount: 0
    property alias filterText: filterField.text

    signal addCue()
    signal insertAfter()
    signal deleteSelected()
    signal followToggled()
    signal timelineTimesToggled()

    function focusFilter() {
        filterField.forceActiveFocus()
        filterField.selectAll()
    }

    implicitHeight: controls.height + countLabel.implicitHeight + Theme.spacingMd * 2

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.c.subtitleCueGrid.borderWidth
        color: Theme.c.subtitleCueGrid.border
    }

    Item {
        id: controls
        x: Theme.spacingMd
        y: Theme.spacingMd
        width: parent.width - Theme.spacingMd * 2
        height: Theme.controlHeight

        Row {
            id: buttons
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXs

            IconButton {
                glyph: Theme.icons.plus
                tooltip: qsTr("Add a cue at the playhead")
                onClicked: root.addCue()
            }

            IconButton {
                glyph: Theme.icons.copyPlus
                enabled: root.canInsertAfter
                tooltip: qsTr("Insert a cue after the selected one")
                onClicked: root.insertAfter()
            }

            IconButton {
                glyph: Theme.icons.trash
                enabled: root.canDelete
                tooltip: qsTr("Delete the selected cues (Delete)")
                onClicked: root.deleteSelected()
            }

            ThemedToggleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Theme.icons.locateFixed
                checked: root.follow
                tooltip: qsTr("Scroll to the current cue during playback")
                onClicked: root.followToggled()
            }

            ThemedToggleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Theme.icons.clock
                checked: root.timelineTimes
                tooltip: qsTr("Show timeline times instead of times within the clip")
                onClicked: root.timelineTimesToggled()
            }
        }

        ThemedTextField {
            id: filterField
            anchors.left: buttons.right
            anchors.leftMargin: Theme.spacingMd
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            placeholderText: qsTr("Filter cues")
            Keys.onEscapePressed: {
                text = ""
                root.parent.forceActiveFocus()
            }
        }
    }

    Text {
        id: countLabel
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMd
        anchors.top: controls.bottom
        anchors.topMargin: Theme.spacingSm
        text: qsTr("%n cue(s)", "", root.cueCount) + " · " + qsTr("%1 selected").arg(root.selectedCount)
        color: Theme.c.subtitleCueGrid.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
