import QtQuick
import Drift
ThemedNumberField {
    id: field

    property real fraction: 0
    signal committed(real fraction)

    width: 64
    decimals: 1
    step: 0.5
    from: 0
    unit: "%"

    Binding on value {
        when: !field.activeFocus
        value: field.fraction * 100
    }
    onEdited: v => field.committed(v / 100)
}
