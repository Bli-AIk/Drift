import QtQuick
import Drift

// Source Lab marks on a bin item: favorite or reject, and how many ranges it holds.
Row {
    id: root

    property int rating: 0
    property int rangeCount: 0

    visible: root.rating !== 0 || root.rangeCount > 0
    spacing: Theme.spacingXs

    IconGlyph {
        visible: root.rating !== 0
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.rating > 0 ? Theme.icons.star : Theme.icons.x
        iconSize: Theme.iconSizeSm
        iconColor: root.rating > 0 ? Theme.c.sourceLabPanel.ratingFavorite : Theme.c.sourceLabPanel.ratingReject
    }

    Rectangle {
        visible: root.rangeCount > 0
        anchors.verticalCenter: parent.verticalCenter
        width: countLabel.implicitWidth + Theme.spacingLg
        height: countLabel.implicitHeight + Theme.spacingSm
        radius: Theme.c.mediaAssetsDurationBadge.radius
        color: Theme.c.mediaAssetsDurationBadge.background

        Text {
            id: countLabel
            anchors.centerIn: parent
            text: root.rangeCount
            color: Theme.c.mediaAssetsDurationBadge.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }
}
