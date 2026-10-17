import QtQuick
import Drift

// Voiceover recording indicator.
Rectangle {
    id: badge

    required property bool paused
    required property real seconds

    height: 28
    radius: Theme.c.previewVoiceoverBadge.radius
    color: Theme.c.previewVoiceoverBadge.background
    border.color: badge.paused ? Theme.c.previewVoiceoverBadge.borderPaused : Theme.c.previewVoiceoverBadge.border
    border.width: Theme.c.previewVoiceoverBadge.borderWidth
    width: recordRow.implicitWidth + 16

    Row {
        id: recordRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 8
            height: 8
            radius: Theme.c.previewVoiceoverBadge.dotRadius
            color: badge.paused ? Theme.c.previewVoiceoverBadge.accentPaused : Theme.c.previewVoiceoverBadge.accent
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: badge.visible && !badge.paused
                loops: Animation.Infinite
                NumberAnimation { to: 0.2; duration: 400 }
                NumberAnimation { to: 1.0; duration: 400 }
            }
        }

        Text {
            text: (badge.paused ? qsTr("PAUSED %1s") : qsTr("REC %1s")).arg(badge.seconds.toFixed(1))
            font.pixelSize: 11
            font.bold: true
            color: Theme.c.previewVoiceoverBadge.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
