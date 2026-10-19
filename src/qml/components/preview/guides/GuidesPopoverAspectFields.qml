import QtQuick
import Drift
// Width : height of an aspect-frame guide.
Row {
    id: aspect

    required property var item
    signal widthEdited(real value)
    signal heightEdited(real value)

    spacing: Theme.spacingSm
    visible: aspect.item.kind === "aspect"

    ThemedNumberField {
        id: aspectW
        width: 64
        decimals: 2
        from: 0.01
        to: 100
        Binding on value {
            when: !aspectW.activeFocus
            value: aspect.item.aspectW
        }
        onEdited: v => aspect.widthEdited(v)
    }
    ThemedLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: ":"
    }
    ThemedNumberField {
        id: aspectH
        width: 64
        decimals: 2
        from: 0.01
        to: 100
        Binding on value {
            when: !aspectH.activeFocus
            value: aspect.item.aspectH
        }
        onEdited: v => aspect.heightEdited(v)
    }
}
