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
    radius: Theme.c.androidOnMediaReadout.radius
    color: Theme.c.androidOnMediaReadout.background
    border.width: Theme.c.androidOnMediaReadout.borderWidth
    border.color: Theme.c.androidOnMediaReadout.border

    Text {
        id: label
        anchors.centerIn: parent
        text: badge.text
        color: Theme.c.androidOnMediaReadout.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
