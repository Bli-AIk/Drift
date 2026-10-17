import QtQuick
import Drift

// Channel name, with a colour dot for armed / master / video / audio.
Item {
    id: nameRow
    property var channel
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32

    Row {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, parent.width - Theme.spacingLg * 2)
        spacing: Theme.spacingSm

        Rectangle {
            id: nameDot
            width: 6
            height: 6
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: nameRow.channel.armed ? (nameRow.channel.armPaused ? "#eab308" : Theme.destructive)
                 : nameRow.channel.master ? Theme.primary
                 : nameRow.channel.isVideo ? Theme.clipVideoOverview : Theme.clipAudio
        }

        Text {
            width: Math.min(implicitWidth, nameRow.width - Theme.spacingLg * 2 - nameDot.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            text: nameRow.channel.name
            elide: Text.ElideRight
            color: nameRow.channel.master ? Theme.accentOnPanel : Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.DemiBold
        }
    }

    HoverHandler { id: nameHover }
    ThemedToolTip {
        visible: nameHover.hovered
        text: nameRow.channel.fullName + (nameRow.channel.armed ? qsTr(" (recording)") : "")
    }
}
