import QtQuick
import Drift

// On-media size and zoom readout under the crop frame.
Rectangle {
    id: badge

    required property string label

    anchors.verticalCenter: parent.verticalCenter
    width: sizeLabel.width + Theme.spacingLg
    height: sizeLabel.height + Theme.spacingSm
    radius: Theme.c.cropOverlaySizeBadge.radius
    // On-media surface, same as the hint: fixed dark scrim
    // with an on-media foreground rather than panel tokens.
    color: Theme.c.cropOverlaySizeBadge.background
    border.width: Theme.c.cropOverlaySizeBadge.borderWidth
    border.color: Theme.c.cropOverlaySizeBadge.border

    Text {
        id: sizeLabel
        anchors.centerIn: parent
        text: badge.label
        color: Theme.c.cropOverlaySizeBadge.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
