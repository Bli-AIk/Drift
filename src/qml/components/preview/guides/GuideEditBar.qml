import QtQuick
import Drift
// "Editing …" plus Done, pinned to the bottom of the viewport.
Rectangle {
    id: bar

    required property string setName
    required property real maxHintWidth
    signal done()

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.spacingLg
    width: barRow.implicitWidth + Theme.spacingLg * 2
    height: barRow.implicitHeight + Theme.spacingMd * 2
    radius: Theme.c.guideEditBar.radius
    color: Theme.c.guideEditBar.background
    border.width: Theme.c.guideEditBar.borderWidth
    border.color: Theme.c.guideEditBar.border

    Row {
        id: barRow
        anchors.centerIn: parent
        spacing: Theme.spacingLg

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: qsTr("Editing %1").arg(bar.setName)
                color: Theme.c.guideEditBar.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
            }
            Text {
                width: Math.min(implicitWidth, bar.maxHintWidth)
                wrapMode: Text.WordWrap
                text: qsTr("Drag from the top or left edge to add a guide, off the canvas to remove one. Shift steps by 1%.")
                color: Theme.c.guideEditBar.foregroundMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            variant: "primary"
            text: qsTr("Done")
            onClicked: bar.done()
        }
    }
}
