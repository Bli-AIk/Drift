import QtQuick
import Drift

// Live size while resizing, the same readout the crop tool shows.
// Keeps the number upright on a rotated frameItem.
Rectangle {
    required property var frameItem
    required property var overlay
    visible: frameItem.resizing
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.bottom
    anchors.topMargin: overlay.gripTouch / 2 + Theme.spacingSm
    width: sizeLabel.width + Theme.spacingLg
    height: sizeLabel.height + Theme.spacingSm
    radius: Theme.c.androidTransformSizeReadout.radius
    // Sits on the preview, not a panel surface, so it uses the fixed
    // scrim and on-media foreground rather than panel tokens.
    color: Theme.c.androidTransformSizeReadout.background
    border.width: Theme.c.androidTransformSizeReadout.borderWidth
    border.color: Theme.c.androidTransformSizeReadout.border
    // Keeps the number upright on a rotated frameItem.
    rotation: -frameItem.rotation

    Text {
        id: sizeLabel
        anchors.centerIn: parent
        text: Math.round(frameItem.layoutW) + "×" + Math.round(frameItem.layoutH)
        color: Theme.c.androidTransformSizeReadout.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
