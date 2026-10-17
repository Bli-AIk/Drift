import QtQuick
import Drift

// Numeric dB scale beside a channel meter.
Item {
    id: dbScale
    property var mixer
    width: 20
    height: parent.height

    Repeater {
        model: [0, -5, -10, -20, -30, -45]
        delegate: Text {
            required property var modelData
            anchors.horizontalCenter: parent.horizontalCenter
            y: 1 + (parent.height - 2) * (1.0 - dbScale.mixer.dbToRatio(modelData)) - height / 2
            text: modelData === 0 ? "0" : String(-modelData)
            color: Theme.c.mixerDbScale.foregroundMuted
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeTick
        }
    }
}
