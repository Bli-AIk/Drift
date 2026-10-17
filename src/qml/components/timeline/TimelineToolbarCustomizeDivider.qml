import QtQuick
import Drift

// Fixed boundary between toolbar buttons and More-menu items.
Row {
    id: dividerRow
    spacing: Theme.spacingMd

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: (parent.width - dividerLabel.width) / 2 - parent.spacing
        height: Theme.borderWidth
        color: Theme.panelBorder
    }
    Text {
        id: dividerLabel
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("More menu")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.DemiBold
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: (parent.width - dividerLabel.width) / 2 - parent.spacing
        height: Theme.borderWidth
        color: Theme.panelBorder
    }
}
