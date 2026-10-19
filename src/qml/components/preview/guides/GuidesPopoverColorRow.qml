import QtQuick
import Drift
// Guide colour and opacity.
Row {
    id: styleRow

    required property var item
    signal colorEdited(string hex)
    signal opacityEdited(real value)

    width: parent ? parent.width : 0
    spacing: Theme.spacingLg

    ColorSwatchField {
        id: colorField
        hex: styleRow.item.color
        tooltip: qsTr("Guide colour")
        onEdited: v => styleRow.colorEdited(v)
    }
    ThemedSlider {
        id: opacitySlider
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - colorField.width - parent.spacing
        label: qsTr("Opacity")
        valueFormatter: v => Math.round(v * 100) + "%"
        Binding on value {
            when: !opacitySlider.pressed
            value: styleRow.item.opacity
        }
        onMoved: styleRow.opacityEdited(value)
    }
}
