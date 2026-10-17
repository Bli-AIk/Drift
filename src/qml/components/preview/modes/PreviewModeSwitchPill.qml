import QtQuick
import Drift

// The sliding checked segment of the 2D / 3D switch.
Rectangle {
    id: pill

    required property real inset
    required property int current
    required property real segmentWidth

    x: pill.inset + pill.current * pill.segmentWidth
    y: pill.inset
    width: pill.segmentWidth
    height: parent.height - pill.inset * 2
    radius: height / 2
    color: Theme.c.previewModeSwitchPill.background
    border.width: Theme.c.previewModeSwitchPill.borderWidth
    border.color: Theme.c.previewModeSwitchPill.border

    Behavior on x {
        NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
    }
}
