import QtQuick
import Drift

// Lane bar: the keyframe lane's collapse toggle, and — while multi-select is
// armed — the controls that gesture has no other home for.
Item {
    id: laneBar

    property bool multiSelectActive: false
    property bool keyframeLaneOpen: false

    signal keyframesToggled()
    signal multiSelectFinished()

    Rectangle {
        anchors.fill: parent
        color: Theme.panelBackground
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.panelBorder
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLg
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSm
        visible: !laneBar.multiSelectActive

        ThemedChip {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Keyframes")
            chipHeight: 26
            selected: laneBar.keyframeLaneOpen
            onClicked: laneBar.keyframesToggled()
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLg
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSm
        visible: laneBar.multiSelectActive

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%n clip(s)", "", EditorState.selectionCount)
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
        ThemedChip {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("All")
            chipHeight: 26
            variant: "outline"
            onClicked: EditorState.selectAllClips()
        }
        ThemedChip {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("None")
            chipHeight: 26
            variant: "outline"
            onClicked: EditorState.clearSelection()
        }
        ThemedChip {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Done")
            chipHeight: 26
            selected: true
            onClicked: laneBar.multiSelectFinished()
        }
    }
}
