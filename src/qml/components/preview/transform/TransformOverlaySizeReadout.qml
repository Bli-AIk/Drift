import QtQuick
import Drift

// Live size while resizing, the same readout the crop tool shows;
// the live angle while rotating.
Rectangle {
    id: readout

    required property bool resizing
    required property bool rotating
    required property real layoutRotation
    required property real layoutW
    required property real layoutH
    // The clip item's own rotation, so the number stays upright on a rotated clip.
    required property real spin

    visible: readout.resizing || readout.rotating
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.bottom
    anchors.topMargin: Theme.spacingLg
    width: sizeLabel.width + Theme.spacingLg
    height: sizeLabel.height + Theme.spacingSm
    radius: Theme.c.transformOverlaySizeReadout.radius
    // Sits on the preview, not a panel surface, so it uses the fixed
    // scrim and on-media foreground rather than panel tokens.
    color: Theme.c.transformOverlaySizeReadout.background
    border.width: Theme.c.transformOverlaySizeReadout.borderWidth
    border.color: Theme.c.transformOverlaySizeReadout.border
    // Keeps the number upright on a rotated clip.
    rotation: -readout.spin

    Text {
        id: sizeLabel
        anchors.centerIn: parent
        text: readout.rotating
              ? Math.round(readout.layoutRotation) + "°"
              : Math.round(readout.layoutW) + "×" + Math.round(readout.layoutH)
        color: Theme.c.transformOverlaySizeReadout.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
