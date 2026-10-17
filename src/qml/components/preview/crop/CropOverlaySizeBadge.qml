import QtQuick
import Drift

// On-media size and zoom readout under the crop frame.
Rectangle {
    id: badge

    required property string label

    anchors.verticalCenter: parent.verticalCenter
    width: sizeLabel.width + Theme.spacingLg
    height: sizeLabel.height + Theme.spacingSm
    radius: Theme.radiusSm
    // On-media surface, same as the hint: fixed dark scrim
    // with an on-media foreground rather than panel tokens.
    color: Theme.scrimStrong
    border.width: Theme.borderWidth
    border.color: Theme.guideWeak

    Text {
        id: sizeLabel
        anchors.centerIn: parent
        text: badge.label
        color: Theme.onMedia
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
