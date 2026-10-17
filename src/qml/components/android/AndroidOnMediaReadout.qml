import QtQuick
import Drift

// A short readout painted over the picture (crop size, live transform size).
// Sits on the preview scrim, not a panel surface, so it uses the on-media tokens —
// panelForeground would go dark-on-dark in light mode.
Rectangle {
    id: badge

    property string text: ""
    property real padH: Theme.spacingLg
    property real padV: Theme.spacingSm

    width: label.width + padH
    height: label.height + padV
    radius: Theme.radiusSm
    color: Theme.scrimStrong
    border.width: Theme.borderWidth
    border.color: Theme.guideWeak

    Text {
        id: label
        anchors.centerIn: parent
        text: badge.text
        color: Theme.onMedia
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
