import QtQuick
import Drift

// Recording tint across a channel strip so an armed track reads from a distance.
Rectangle {
    property bool armed: false
    anchors.fill: parent
    visible: armed
    color: Theme.c.mixerChannelArmTint.background
}
