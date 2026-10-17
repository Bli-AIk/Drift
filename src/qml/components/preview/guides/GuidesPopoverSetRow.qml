import QtQuick
import Drift
// One guide set: show checkbox, name, and where it came from.
Rectangle {
    id: setRow

    required property var modelData
    required property string selectedId
    property real rowWidth: 0
    readonly property bool chosen: modelData.id === setRow.selectedId

    signal picked(string id)

    width: setRow.rowWidth
    height: Theme.controlHeight + Theme.spacingXs
    radius: Theme.radiusSm
    color: setRow.chosen ? Theme.accent
           : setHover.hovered ? Theme.popoverHover : "transparent"

    HoverHandler { id: setHover }
    TapHandler { onTapped: setRow.picked(setRow.modelData.id) }

    ThemedCheckBox {
        id: activeBox
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        checked: setRow.modelData.active
        tooltip: qsTr("Show this set")
        onToggled: EditorState.setGuideSetActive(setRow.modelData.id, checked)
    }

    Text {
        anchors.left: activeBox.right
        anchors.right: originLabel.left
        anchors.rightMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        text: setRow.modelData.name
        elide: Text.ElideRight
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
    }

    Text {
        id: originLabel
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        text: setRow.modelData.builtIn ? qsTr("Built-in")
              : setRow.modelData.inLibrary ? "" : qsTr("From project")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
