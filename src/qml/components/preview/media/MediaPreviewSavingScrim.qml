import QtQuick
import Drift
Rectangle {
    id: scrim

    required property string status
    required property real progress

    anchors.fill: parent
    color: Theme.c.mediaPreviewSavingScrim.background
    z: 10

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingLg
        width: Math.min(parent.width - Theme.spacing3xl * 2, 320)

        ThemedLabel {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: scrim.status
            tone: "default"
            size: "sm"
        }
        ThemedProgressBar {
            width: parent.width
            value: scrim.progress
        }
    }
}
