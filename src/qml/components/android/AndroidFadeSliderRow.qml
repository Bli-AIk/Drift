import QtQuick
import Drift

// One edge of a clip's fade. The drag is a preview edit committed on release,
// the same undo a desktop fade-dot drag produced.
Column {
    id: fadeRow

    required property var modelData
    property real current: 0
    property real maxFade: 0.1
    property var formatSeconds: function(v) { return "" }

    signal previewBegan()
    signal previewEnded()
    signal moved(real value)

    spacing: Theme.spacingSm

    Item {
        width: parent.width
        height: Math.max(fadeLabel.implicitHeight, fadeValue.implicitHeight)

        ThemedLabel {
            id: fadeLabel
            anchors.left: parent.left
            text: fadeRow.modelData.label
            size: "sm"
        }
        Text {
            id: fadeValue
            anchors.right: parent.right
            text: fadeRow.formatSeconds(fadeSlider.pressed ? fadeSlider.value : fadeRow.current)
            color: Theme.mutedForeground
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeSm
        }
    }

    ThemedSlider {
        id: fadeSlider
        width: parent.width
        from: 0
        to: fadeRow.maxFade
        stepSize: 0.1
        label: fadeRow.modelData.label
        valueFormatter: fadeRow.formatSeconds
        Binding on value {
            when: !fadeSlider.pressed
            value: fadeRow.current
        }
        onPressedChanged: {
            if (pressed)
                fadeRow.previewBegan()
            else
                fadeRow.previewEnded()
        }
        onMoved: fadeRow.moved(value)
    }
}
