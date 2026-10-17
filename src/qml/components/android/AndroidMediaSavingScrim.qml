import QtQuick
import Drift

// Blocks the page while a bin edit is written back.
Rectangle {
    id: scrim

    property real progress: 0
    property string statusText: ""

    signal cancelRequested()

    color: Theme.scrimColor

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingLg
        width: Math.min(parent.width - Theme.spacing3xl * 2, 320)

        ThemedLabel {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: scrim.statusText
            size: "sm"
        }
        ThemedProgressBar {
            width: parent.width
            value: scrim.progress
        }
        ThemedButton {
            anchors.horizontalCenter: parent.horizontalCenter
            variant: "ghost"
            text: qsTr("Cancel")
            onClicked: scrim.cancelRequested()
        }
    }
}
