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
    radius: Theme.c.guideEditReadout.radius
    color: Theme.c.guideEditReadout.background
    border.width: Theme.c.guideEditReadout.borderWidth
    border.color: Theme.c.guideEditReadout.border

    Text {
        id: readoutText
        anchors.centerIn: parent
        text: readout.label
        color: Theme.c.guideEditReadout.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
