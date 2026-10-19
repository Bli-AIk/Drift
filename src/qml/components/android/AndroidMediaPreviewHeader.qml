import QtQuick
import Drift

// Back, the asset name, and Save. The name is elided in the middle: a bin
// path is long enough to wrap and spill out of the bar.
Item {
    id: header

    property string assetName: ""
    property bool canSave: false
    property bool backEnabled: true

    signal backRequested()
    signal saveRequested()

    Rectangle {
        anchors.fill: parent
        color: Theme.c.androidMediaPreviewHeader.background
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.c.androidMediaPreviewHeader.borderWidth
        color: Theme.c.androidMediaPreviewHeader.border
    }

    IconButton {
        id: backButton
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        buttonSize: Theme.androidIconButtonSize
        glyph: Theme.icons.chevronLeft
        tooltip: qsTr("Back")
        enabled: header.backEnabled
        onClicked: header.backRequested()
    }

    ThemedLabel {
        anchors.left: backButton.right
        anchors.right: saveButton.left
        anchors.leftMargin: Theme.spacingSm
        anchors.rightMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        text: header.assetName
        // ThemedLabel wraps by default, and a bin name is long enough to take the header
        // to two lines and spill out of it.
        wrapMode: Text.NoWrap
        elide: Text.ElideMiddle
        size: "sm"
        tone: "default"
    }

    ThemedButton {
        id: saveButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        variant: "primary"
        text: qsTr("Save")
        enabled: header.canSave
        onClicked: header.saveRequested()
    }
}
