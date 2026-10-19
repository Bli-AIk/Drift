import QtQuick
import Drift

// Expanding ring behind the Extras icon — reads as a soft shockwave, not a badge.
Item {
    id: wave
    required property int index
    property bool attention

    anchors.centerIn: parent
    width: Theme.iconButtonSize
    height: Theme.iconButtonSize
    scale: 0.85
    opacity: 0
    visible: wave.attention
    z: -1

    Rectangle {
        anchors.fill: parent
        radius: Theme.c.editorHeaderExtrasWave.radius
        color: "transparent"
        border.width: Theme.c.editorHeaderExtrasWave.borderWidth
        border.color: Theme.c.editorHeaderExtrasWave.border
    }

    SequentialAnimation {
        running: wave.attention
        loops: Animation.Infinite

        PauseAnimation { duration: wave.index * 700 }
        ParallelAnimation {
            NumberAnimation {
                target: wave
                property: "opacity"
                from: 0.55
                to: 0
                duration: 1400
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: wave
                property: "scale"
                from: 0.85
                to: 1.75
                duration: 1400
                easing.type: Easing.OutCubic
            }
        }
        PauseAnimation { duration: (1 - wave.index) * 700 }
    }
}
