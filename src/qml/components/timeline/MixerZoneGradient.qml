import QtQuick
import Drift

// Meter zone colours. `vivid` is the live level; muted tints mark the scale at rest.
Gradient {
    id: zones
    property bool vivid: false
    readonly property color red: zones.vivid ? Theme.destructive
                                       : (Theme.darkMode ? "#4a2c2c" : "#f1d4d1")
    readonly property color yellow: zones.vivid ? Theme.primary
                                          : (Theme.darkMode ? "#453c22" : "#f2e7c4")
    readonly property color green: zones.vivid ? Theme.constructive
                                         : (Theme.darkMode ? "#26392d" : "#d6e8da")
    GradientStop { position: 0.00; color: zones.red }
    GradientStop { position: 0.15; color: zones.red }
    GradientStop { position: 0.15; color: zones.yellow }
    GradientStop { position: 0.33; color: zones.yellow }
    GradientStop { position: 0.33; color: zones.green }
    GradientStop { position: 1.00; color: zones.green }
}
