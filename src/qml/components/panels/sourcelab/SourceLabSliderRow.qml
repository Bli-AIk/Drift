import QtQuick
import Drift

// A labelled slider with a typed value beside it. With logScale the slider runs in octaves, so
// 0.25x to 4x puts 1x in the middle; detents pull the value onto the listed stops.
Item {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property int decimals: 1
    property real step: 0.1
    property string unit: ""
    property bool logScale: false
    property var detents: []

    signal moved(real value)

    width: parent ? parent.width : 200
    implicitHeight: column.height

    function toPos(v) {
        return root.logScale ? Math.log(Math.max(v, 1e-6)) / Math.LN2 : v
    }

    function fromPos(p) {
        return root.logScale ? Math.pow(2, p) : p
    }

    function snap(v) {
        const span = root.toPos(root.to) - root.toPos(root.from)
        for (const d of root.detents) {
            if (Math.abs(root.toPos(v) - root.toPos(d)) < span * 0.02)
                return d
        }
        const k = Math.pow(10, root.decimals + 1)
        return Math.round(v * k) / k
    }

    function text(v) {
        return Number(v).toFixed(root.decimals) + (root.unit.length > 0 ? " " + root.unit : "")
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.spacingSm

        Item {
            width: parent.width
            height: field.implicitHeight

            ThemedLabel {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
            }
            ThemedNumberField {
                id: field
                anchors.right: parent.right
                width: 96
                from: root.from
                to: root.to
                step: root.step
                decimals: root.decimals
                unit: root.unit
                Binding on value {
                    when: !field.activeFocus
                    value: root.value
                }
                onEdited: v => root.moved(v)
            }
        }

        ThemedSlider {
            id: slider
            width: parent.width
            label: root.label
            from: root.toPos(root.from)
            to: root.toPos(root.to)
            valueFormatter: p => root.text(root.fromPos(p))
            Binding on value {
                when: !slider.pressed
                value: root.toPos(root.value)
            }
            onMoved: {
                const v = root.snap(root.fromPos(value))
                value = root.toPos(v)
                root.moved(v)
            }
        }
    }
}
