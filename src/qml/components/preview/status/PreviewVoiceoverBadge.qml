import QtQuick
import Drift

// Voiceover recording indicator.
Rectangle {
    id: badge

    required property bool paused
    required property real seconds

    height: 28
    radius: Theme.radiusSm
    color: Qt.rgba(0, 0, 0, 0.75)
    border.color: badge.paused ? "#eab308" : Theme.destructive
    border.width: 1
    width: recordRow.implicitWidth + 16

    Row {
        id: recordRow
        anchors.centerIn: parent
        spacing: 6

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: badge.paused ? "#eab308" : Theme.destructive
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
            color: Theme.panelForeground
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
