import QtQuick
import Drift

// Number badge — the key that switches to this angle.
Rectangle {
    id: badge

    required property int number
    required property bool active

    x: Theme.spacingSm
    y: Theme.spacingSm
    width: badgeText.width + Theme.spacingMd
    height: badgeText.height + Theme.spacingXs
    radius: Theme.radiusSm
    color: badge.active ? Theme.primary : Theme.scrimStrong

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: badge.number
        color: badge.active ? Theme.primaryForeground : "#ffffff"
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
    }
}
