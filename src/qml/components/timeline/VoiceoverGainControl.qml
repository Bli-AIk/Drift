import QtQuick
import Drift

// Mic gain slider and its percent readout.
Item {
    id: gainContainer
    width: gainRow.implicitWidth
    height: 24
    anchors.verticalCenter: parent.verticalCenter

    Row {
        id: gainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        IconGlyph {
            glyph: Theme.icons.volumeHigh
            iconSize: 13
            iconColor: Theme.mutedForeground
            anchors.verticalCenter: parent.verticalCenter
        }

        ThemedSlider {
            id: gainSlider
            label: qsTr("Mic gain")
            width: 65
            anchors.verticalCenter: parent.verticalCenter
            from: 0.0
            to: 2.0
            value: EditorState.audioRecordGain
            onMoved: EditorState.setAudioRecordGain(value)
            valueFormatter: function (v) {
                return Math.round(v * 100) + "%"
            }
        }

        Text {
            text: Math.round(EditorState.audioRecordGain * 100) + "%"
            font.family: Theme.monoFontFamily
            font.pixelSize: 10
            color: Theme.mutedForeground
            width: 32
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    ThemedToolTip {
        text: qsTr("Voice input gain: %1% (adjust voice level)").arg(Math.round(EditorState.audioRecordGain * 100))
        visible: gainMouse.containsMouse
    }

    MouseArea {
        id: gainMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
