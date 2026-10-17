import QtQuick
import Drift

// Meter zone colours. `vivid` is the live level; muted tints mark the scale at rest.
Gradient {
    id: zones
    property bool vivid: false
    readonly property color red: zones.vivid ? Theme.c.mixerZoneGradient.red
                                       : Theme.c.mixerZoneGradient.redMuted
    readonly property color yellow: zones.vivid ? Theme.c.mixerZoneGradient.yellow
                                          : Theme.c.mixerZoneGradient.yellowMuted
    readonly property color green: zones.vivid ? Theme.c.mixerZoneGradient.green
                                         : Theme.c.mixerZoneGradient.greenMuted
    GradientStop { position: 0.00; color: zones.red }
    GradientStop { position: 0.15; color: zones.red }
    GradientStop { position: 0.15; color: zones.yellow }
    GradientStop { position: 0.33; color: zones.yellow }
    GradientStop { position: 0.33; color: zones.green }
    GradientStop { position: 1.00; color: zones.green }
}
