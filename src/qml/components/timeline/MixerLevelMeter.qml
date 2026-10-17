import QtQuick

// Stereo peak meter. Zones stay fixed to the scale, so only the part above a threshold changes colour.
Item {
    id: meter

    property var mixer
    property real levelL: 0
    property real levelR: 0
    property real peakL: 0
    property real peakR: 0

    readonly property real innerH: height - 2

    implicitWidth: 16

    MixerMeterChannel {
        x: 1
        y: 1
        width: meter.width / 2 - 2
        height: meter.innerH
        mixer: meter.mixer
        level: meter.levelL
        peak: meter.peakL
    }
    MixerMeterChannel {
        x: meter.width / 2 + 1
        y: 1
        width: meter.width / 2 - 2
        height: meter.innerH
        mixer: meter.mixer
        level: meter.levelR
        peak: meter.peakR
    }

    Repeater {
        model: [0, -5, -10, -20, -30, -45]
        delegate: MixerMeterTick {
            meterItem: meter
        }
    }
}
