import QtQuick
import Drift

Item {
    id: root

    property string label: ""
    property real value: 0
    property real from: -1
    property real to: 1
    property real defaultValue: 0
    property real stepSize: 0.01
    property int decimals: 2
    property bool bipolar: true
    property var gradient: []

    signal began()
    signal moved(real value)
    signal ended()
    signal reset()

    readonly property bool gradientActive: gradient && gradient.length >= 2
    readonly property real span: Math.max(1e-9, to - from)

    function resetToDefault() {
        began()
        moved(defaultValue)
        ended()
        reset()
    }

    implicitWidth: 200
    implicitHeight: header.height + slider.height + Theme.spacingXs

    Item {
        id: header
        width: parent.width
        height: Theme.controlHeightSm

        Text {
            anchors.left: parent.left
            anchors.right: field.left
            anchors.rightMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.label
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs

            TapHandler {
                onDoubleTapped: root.resetToDefault()
            }
        }

        ThemedNumberField {
            id: field
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            from: root.from
            to: root.to
            step: root.stepSize
            decimals: root.decimals
            value: root.value
            onEdited: v => {
                root.began()
                root.moved(v)
                root.ended()
            }
        }
    }

    ThemedSlider {
        id: slider
        y: header.height + Theme.spacingXs
        width: parent.width
        label: root.label
        from: root.from
        to: root.to
        stepSize: root.stepSize
        showValueTooltip: false
        valueFormatter: v => Number(v).toFixed(root.decimals)

        Binding on value {
            when: !slider.pressed
            value: root.value
        }

        onPressedChanged: {
            if (pressed)
                root.began()
            else
                root.ended()
        }
        onMoved: {
            if (pressed) {
                root.moved(value)
                return
            }
            root.began()
            root.moved(value)
            root.ended()
        }

        TapHandler {
            onDoubleTapped: root.resetToDefault()
        }

        background: Item {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: Theme.spacingSm

            Rectangle {
                anchors.fill: parent
                radius: Theme.c.themedSlider.trackRadius
                color: Theme.c.themedSlider.trackBackground
                visible: !root.gradientActive
            }

            Canvas {
                id: gradientTrack
                anchors.fill: parent
                visible: root.gradientActive
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Connections {
                    target: root
                    function onGradientChanged() { gradientTrack.requestPaint() }
                }
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const stops = root.gradient
                    if (!stops || stops.length < 2 || width < 2)
                        return
                    const g = ctx.createLinearGradient(0, 0, width, 0)
                    for (let i = 0; i < stops.length; ++i)
                        g.addColorStop(i / (stops.length - 1), String(stops[i]))
                    const r = height / 2
                    ctx.fillStyle = g
                    ctx.beginPath()
                    ctx.moveTo(r, 0)
                    ctx.lineTo(width - r, 0)
                    ctx.arc(width - r, r, r, -Math.PI / 2, Math.PI / 2)
                    ctx.lineTo(r, height)
                    ctx.arc(r, r, r, Math.PI / 2, 3 * Math.PI / 2)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Rectangle {
                readonly property real startPos: root.bipolar
                    ? Math.min(1, Math.max(0, (root.defaultValue - root.from) / root.span)) : 0
                x: Math.min(startPos, slider.visualPosition) * parent.width
                width: Math.abs(slider.visualPosition - startPos) * parent.width
                height: parent.height
                radius: parent.height / 2
                color: Theme.c.themedSlider.fillBackground
                visible: !root.gradientActive
            }

            Rectangle {
                visible: root.bipolar
                x: Math.min(1, Math.max(0, (root.defaultValue - root.from) / root.span)) * parent.width
                   - width / 2
                y: -1
                width: 1
                height: parent.height + 2
                color: Theme.panelForeground
                opacity: 0.35
            }
        }
    }
}
