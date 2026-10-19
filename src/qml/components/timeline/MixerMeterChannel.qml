import QtQuick
import Drift

// One bar of a stereo meter: resting zones, live level, and a peak-hold mark.
Item {
    id: channel

    property var mixer
    property real level: 0
    property real peak: 0

    readonly property real levelRatio: mixer.dbToRatio(mixer.linearToDb(level))
    readonly property real peakRatio: mixer.dbToRatio(mixer.linearToDb(peak))

    Rectangle {
        anchors.fill: parent
        radius: Theme.c.mixerMeterChannel.radius
        gradient: MixerZoneGradient {}
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(0, Math.min(1, channel.levelRatio)) * parent.height
        clip: true

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: channel.height
            radius: Theme.c.mixerMeterChannel.radius
            gradient: MixerZoneGradient { vivid: true }
        }
    }

    // Peak hold; red once the held peak has crossed 0 dBFS.
    Rectangle {
        visible: channel.peak > 0.001
        width: parent.width
        height: 2
        y: Math.max(0, parent.height * (1.0 - channel.peakRatio) - 1)
        color: channel.peak >= 1.0 ? Theme.c.mixerMeterChannel.peakHot : Theme.c.mixerMeterChannel.peak
    }
}
