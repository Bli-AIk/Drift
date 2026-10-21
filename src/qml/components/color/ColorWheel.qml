import QtQuick
import Drift

Item {
    id: root

    property string label: ""
    property point offset: Qt.point(0, 0)
    property real luma: 0
    property real size: 140

    signal began()
    signal offsetMoved(real x, real y)
    signal lumaMoved(real v)
    signal ended()

    readonly property real radius: size / 2
    readonly property real puckSize: 12
    property point liveOffset: offset
    readonly property point shown: drag.pressed ? liveOffset : offset

    function resetOffset() {
        began()
        offsetMoved(0, 0)
        ended()
    }

    implicitWidth: size
    width: implicitWidth
    implicitHeight: header.height + size + lumaSlider.height + Theme.spacingMd * 2

    Item {
        id: header
        width: parent.width
        height: Theme.controlHeightSm

        Text {
            anchors.left: parent.left
            anchors.right: resetButton.left
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.label
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }

        IconButton {
            id: resetButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.reset
            tooltip: qsTr("Reset %1").arg(root.label)
            buttonSize: Theme.controlHeightSm
            onClicked: root.resetOffset()
        }
    }

    Item {
        id: disc
        y: header.height + Theme.spacingMd
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.size
        height: root.size

        // The tint at (x, y) is the YIQ shift the grade shader applies for that offset, so what
        // the user sees under the puck is what the footage gets. 0.6 keeps the rim unclipped.
        Canvas {
            id: hueDisc
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const w = Math.floor(width)
                const h = Math.floor(height)
                if (w < 2 || h < 2)
                    return
                const ctx = getContext("2d")
                const img = ctx.createImageData(w, h)
                const px = img.data
                const rad = Math.min(w, h) / 2
                const k = 0.6
                const clamp = v => Math.min(1, Math.max(0, v))
                for (let j = 0; j < h; ++j) {
                    for (let i = 0; i < w; ++i) {
                        const dx = (i + 0.5 - w / 2) / rad
                        const dy = -(j + 0.5 - h / 2) / rad
                        const dist = Math.sqrt(dx * dx + dy * dy)
                        const cover = Math.min(1, Math.max(0, (1 - dist) * rad))
                        if (cover <= 0)
                            continue
                        const yi = 0.5957 * dx
                        const yq = 0.5226 * dy
                        const o = (j * w + i) * 4
                        px[o] = Math.round(clamp(0.5 + k * (0.956 * yi + 0.619 * yq)) * 255)
                        px[o + 1] = Math.round(clamp(0.5 + k * (-0.272 * yi - 0.647 * yq)) * 255)
                        px[o + 2] = Math.round(clamp(0.5 + k * (-1.106 * yi + 1.703 * yq)) * 255)
                        px[o + 3] = Math.round(cover * 255)
                    }
                }
                ctx.reset()
                ctx.putImageData(img, 0, 0)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: Theme.c.vec2ParamPad.borderWidth
            border.color: drag.pressed ? Theme.c.vec2ParamPad.borderPressed
                                       : Theme.c.vec2ParamPad.border
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.c.vec2ParamPad.crosshairWidth
            height: parent.height
            color: Theme.c.vec2ParamPad.crosshair
            opacity: Theme.c.vec2ParamPad.crosshairOpacity
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Theme.c.vec2ParamPad.crosshairWidth
            color: Theme.c.vec2ParamPad.crosshair
            opacity: Theme.c.vec2ParamPad.crosshairOpacity
        }

        Rectangle {
            width: root.puckSize
            height: root.puckSize
            radius: width / 2
            color: Theme.c.vec2ParamPad.handleBackground
            border.width: Theme.c.vec2ParamPad.handleBorderWidth
            border.color: Theme.c.vec2ParamPad.handleBorder
            x: root.radius + root.shown.x * root.radius - width / 2
            y: root.radius - root.shown.y * root.radius - height / 2
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            preventStealing: true

            property real lastX: 0
            property real lastY: 0
            property var lockedFlickable: null

            function lockFlickable() {
                if (lockedFlickable)
                    return
                let node = root.parent
                while (node) {
                    if (node.dragLocks !== undefined && node.contentHeight !== undefined) {
                        lockedFlickable = node
                        node.dragLocks++
                        return
                    }
                    node = node.parent
                }
            }
            function unlockFlickable() {
                if (lockedFlickable) {
                    lockedFlickable.dragLocks = Math.max(0, lockedFlickable.dragLocks - 1)
                    lockedFlickable = null
                }
            }
            function finish() {
                unlockFlickable()
                root.ended()
            }

            Component.onDestruction: unlockFlickable()

            onPressed: mouse => {
                lockFlickable()
                lastX = mouse.x
                lastY = mouse.y
                root.liveOffset = root.offset
                root.began()
            }
            onPositionChanged: mouse => {
                if (!pressed)
                    return
                const fine = (mouse.modifiers & Qt.ShiftModifier) ? 0.25 : 1
                let nx = root.liveOffset.x + (mouse.x - lastX) / root.radius * fine
                let ny = root.liveOffset.y - (mouse.y - lastY) / root.radius * fine
                lastX = mouse.x
                lastY = mouse.y
                const len = Math.sqrt(nx * nx + ny * ny)
                if (len > 1) {
                    nx /= len
                    ny /= len
                }
                root.liveOffset = Qt.point(nx, ny)
                root.offsetMoved(nx, ny)
            }
            onReleased: finish()
            onCanceled: finish()
            onDoubleClicked: root.resetOffset()
        }
    }

    GradeSlider {
        id: lumaSlider
        y: disc.y + root.size + Theme.spacingMd
        width: parent.width
        label: qsTr("Brightness")
        from: -1
        to: 1
        defaultValue: 0
        value: root.luma
        gradient: ["#000000", "#ffffff"]
        onBegan: root.began()
        onMoved: v => root.lumaMoved(v)
        onEnded: root.ended()
    }
}
