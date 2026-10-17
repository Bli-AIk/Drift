import QtQuick
import Drift

// Percent (or "release to remove") next to the pointer.
Rectangle {
    id: readout

    required property string label
    required property real pointerX
    required property real pointerY

    x: Math.min(parent.width - width, readout.pointerX + Theme.spacingLg)
    y: Math.min(parent.height - height, readout.pointerY + Theme.spacingLg)
    width: readoutText.implicitWidth + Theme.spacingMd * 2
    height: readoutText.implicitHeight + Theme.spacingSm * 2
    radius: Theme.radiusSm
    color: Theme.panelBackground
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    Text {
        id: readoutText
        anchors.centerIn: parent
        text: readout.label
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
