import QtQuick
import Drift

// Only the buttons: the text is edited on the preview itself, which stays visible above this.
Rectangle {
    id: bar

    property bool editing: false
    // InlineTextEditor on the preview. cancel / selectAll / commit.
    property var textEditor: null

    readonly property real coveredHeight: editing ? height + anchors.bottomMargin : 0

    height: Theme.iconButtonSize + Theme.spacingMd * 2
    visible: editing
    color: Theme.panelBackground

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: Theme.borderWidth
        color: Theme.panelBorder
    }

    // Swallows touches that miss a control so they do not fall through to the timeline below.
    MouseArea {
        anchors.fill: parent
    }

    IconButton {
        id: cancelEditButton
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        focusPolicy: Qt.NoFocus
        glyph: Theme.icons.x
        tooltip: qsTr("Cancel")
        onClicked: bar.textEditor.cancel()
    }

    ThemedButton {
        anchors.left: cancelEditButton.right
        anchors.leftMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        focusPolicy: Qt.NoFocus
        text: qsTr("Select all")
        onClicked: bar.textEditor.selectAll()
    }

    ThemedButton {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        focusPolicy: Qt.NoFocus
        variant: "primary"
        glyph: Theme.icons.check
        text: qsTr("Done")
        onClicked: bar.textEditor.commit()
    }
}
