import QtQuick
import Drift

Rectangle {
    property var host
    id: root
    width: parent.width
    height: Math.min(parent.width * 0.6, 140)
    radius: Theme.c.vec2ParamPad.radius
    color: Theme.c.vec2ParamPad.background
    border.width: Theme.c.vec2ParamPad.borderWidth
    border.color: dragArea.pressed ? Theme.c.vec2ParamPad.borderPressed : Theme.c.vec2ParamPad.border

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.c.vec2ParamPad.crosshairWidth
        height: parent.height
        color: Theme.c.vec2ParamPad.crosshair
        opacity: Theme.c.vec2ParamPad.crosshairOpacity
    }
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.c.vec2ParamPad.crosshairWidth
        width: parent.width
        color: Theme.c.vec2ParamPad.crosshair
        opacity: Theme.c.vec2ParamPad.crosshairOpacity
    }
    Rectangle {
        width: 12
        height: 12
        radius: Theme.c.vec2ParamPad.handleRadius
        color: Theme.c.vec2ParamPad.handleBackground
        border.width: Theme.c.vec2ParamPad.handleBorderWidth
        border.color: Theme.c.vec2ParamPad.handleBorder
        readonly property real span: host.hi - host.lo
        x: (span > 0 ? (host.curX - host.lo) / span : 0) * root.width - width / 2
        // Up is larger Y, matching the shader's bottom-left uv origin.
        y: (1 - (span > 0 ? (host.curY - host.lo) / span : 0)) * root.height - height / 2
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        // Stops a parent Flickable taking the drag over, as ThemedSlider does: only Flickables
        // that opt in with `dragLocks` and fold it into `interactive` can be locked.
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
        preventStealing: true
        Component.onDestruction: unlockFlickable()
        function update(mouse) {
            const fx = Math.min(1, Math.max(0, mouse.x / width))
            const fy = Math.min(1, Math.max(0, mouse.y / height))
            host.preview(host.lo + fx * (host.hi - host.lo),
                         host.lo + (1 - fy) * (host.hi - host.lo))
        }
        onPressed: mouse => {
            lockFlickable()
            EditorState.beginPreviewDrag(qsTr("Edit %1").arg(host.paramData.label))
            update(mouse)
        }
        onPositionChanged: mouse => { if (pressed) update(mouse) }
        onReleased: {
            unlockFlickable()
            EditorState.commitPreviewDrag()
            host.liveX = NaN
            host.liveY = NaN
        }
        onCanceled: {
            unlockFlickable()
            EditorState.commitPreviewDrag()
            host.liveX = NaN
            host.liveY = NaN
        }
    }
}
