pragma ComponentBehavior: Bound
import QtQuick
import Drift
import ".."

// In-place editing of a text clip on the preview, where the compositor's render is the only
// visible text: it draws the caret, the selection tint and the preedit underline itself. This
// item draws none of that. A hidden TextEdit owns the text, the selection, the keyboard and the
// input method; each change is pushed to EditorState.updateInlineTextEdit, and the engine's
// layout answers every tap, drag and arrow key (hit test, word, line moves) so the caret lands
// where the render says it is. Touch selection handles are the only thing drawn here.
//
// Sits over the whole viewport, above the interaction tools, and takes the pointer while active.
Item {
    id: root

    // The canvas rect inside this item's parent, which the project's px map onto.
    property Item canvas

    property bool active: false
    property int editTrack: -1
    property int editClip: -1
    // Selection handles are for fingers. Set from the input that last touched the editor.
    property bool touchMode: Qt.platform.os === "android" || Qt.platform.os === "ios"

    readonly property real handleTouch: 44
    readonly property real handleSize: 20

    anchors.fill: parent
    visible: active

    readonly property real projectW: {
        void EditorState.tracksRevision
        return Math.max(1, EditorState.projectFile.projectWidth())
    }
    readonly property real projectH: {
        void EditorState.tracksRevision
        return Math.max(1, EditorState.projectFile.projectHeight())
    }

    function toItem(p) {
        return Qt.point(canvas.x + p.x * canvas.width / projectW,
                        canvas.y + p.y * canvas.height / projectH)
    }

    function toCanvas(p) {
        return Qt.point((p.x - canvas.x) * projectW / Math.max(1, canvas.width),
                        (p.y - canvas.y) * projectH / Math.max(1, canvas.height))
    }

    property int geometryRevision: 0
    readonly property var caretQuad: {
        void geometryRevision
        return active ? EditorState.inlineCaretQuad() : []
    }
    readonly property var selectionQuads: {
        void geometryRevision
        return active ? EditorState.inlineSelectionQuads() : []
    }

    readonly property bool hasCaret: caretQuad.length === 4
    readonly property point caretTopLeft: hasCaret ? toItem(caretQuad[0]) : Qt.point(0, 0)
    readonly property point caretBottomLeft: hasCaret ? toItem(caretQuad[3]) : Qt.point(0, 0)
    readonly property point caretBottomRight: hasCaret ? toItem(caretQuad[2]) : Qt.point(0, 0)
    readonly property point caretTip: Qt.point((caretBottomLeft.x + caretBottomRight.x) / 2,
                                               (caretBottomLeft.y + caretBottomRight.y) / 2)
    readonly property real caretHeight: Math.hypot(caretBottomLeft.x - caretTopLeft.x,
                                                   caretBottomLeft.y - caretTopLeft.y)

    readonly property bool hasSelection: proxy.selectionStart !== proxy.selectionEnd
                                         && selectionQuads.length > 0
    readonly property point selectionStartTip: hasSelection ? toItem(selectionQuads[0][3]) : Qt.point(0, 0)
    readonly property point selectionEndTip: hasSelection
        ? toItem(selectionQuads[selectionQuads.length - 1][2]) : Qt.point(0, 0)

    property bool _ready: false
    property bool _dirty: false
    property bool _starting: false

    function start(trackIndex, clipIndex, selectAllText) {
        const data = EditorState.clipAt(trackIndex, clipIndex)
        if (!data || data.kind !== "text")
            return
        if (root.active)
            root.commit()
        EditorState.playing = false
        // The clip has to be on screen for the engine to lay it out.
        const now = EditorState.playheadSeconds
        if (now < data.start || now >= data.start + data.duration)
            EditorState.playheadSeconds = data.start
        EditorState.selectClip(trackIndex, clipIndex)
        EditorState.beginInlineTextEdit(trackIndex, clipIndex)
        if (!EditorState.inlineTextEditing)
            return

        root._ready = false
        root._starting = true
        root.editTrack = trackIndex
        root.editClip = clipIndex
        root.active = true
        proxy.text = data.textContent || ""
        if (selectAllText)
            proxy.selectAll()
        else
            proxy.cursorPosition = proxy.length
        proxy.forceActiveFocus()
        root._ready = true
        root._dirty = true
        root.flush()
        if (root.touchMode)
            Qt.inputMethod.show()
        // Whatever took focus in the same gesture gets it back; focus lost after this is the
        // user leaving.
        Qt.callLater(function () {
            if (root.active && !proxy.activeFocus)
                proxy.forceActiveFocus()
            root._starting = false
        })
    }

    function commit() {
        root.finish(true)
    }

    function cancel() {
        root.finish(false)
    }

    function selectAll() {
        proxy.selectAll()
    }

    function finish(accept) {
        if (!root.active)
            return
        if (accept && proxy.preeditText !== "")
            Qt.inputMethod.commit()
        root.flush()
        root.active = false
        root._ready = false
        EditorState.endInlineTextEdit(accept)
        proxy.focus = false
        Qt.inputMethod.hide()
    }

    function flush() {
        if (!root.active || !root._ready || !root._dirty)
            return
        root._dirty = false
        const s = proxy.selectionStart
        const e = proxy.selectionEnd
        EditorState.updateInlineTextEdit(root.editTrack, root.editClip, proxy.text, proxy.cursorPosition,
                                         s === e ? -1 : s, s === e ? -1 : e, proxy.preeditText)
    }

    function markDirty() {
        if (!root._ready)
            return
        root._dirty = true
        Qt.callLater(root.flush)
    }

    function moveCaret(pos, extend) {
        const hasRange = proxy.selectionStart !== proxy.selectionEnd
        const anchor = !hasRange ? proxy.cursorPosition
                       : proxy.cursorPosition === proxy.selectionStart ? proxy.selectionEnd
                                                                       : proxy.selectionStart
        proxy.select(extend ? anchor : pos, pos)
    }

    function hitAt(pos) {
        root.flush()
        return EditorState.inlineHitTest(root.toCanvas(pos))
    }

    // Whether a canvas point is on the edited clip, so a tap elsewhere can end the edit.
    function insideClip(cp) {
        for (const b of EditorState.preview.clipsAtPlayhead()) {
            if (b.track !== root.editTrack || b.clip !== root.editClip)
                continue
            if (b.parentActive || b.cameraActive || b.layer3d)
                break
            const r = (b.rotation || 0) * Math.PI / 180
            const dx = cp.x - (b.x + b.width / 2)
            const dy = cp.y - (b.y + b.height / 2)
            const lx = dx * Math.cos(-r) - dy * Math.sin(-r)
            const ly = dx * Math.sin(-r) + dy * Math.cos(-r)
            return Math.abs(lx) <= b.width / 2 && Math.abs(ly) <= b.height / 2
        }
        const hit = EditorState.preview.clipAtCanvasPoint(cp.x, cp.y)
        return !!hit && hit.track === root.editTrack && hit.clip === root.editClip
    }

    function overHandle(pos) {
        for (const h of [caretHandle, startHandle, endHandle]) {
            if (!h.visible)
                continue
            const p = h.mapFromItem(root, pos.x, pos.y)
            if (h.contains(p))
                return true
        }
        return false
    }

    function handleTap(pos, count, extend, fromTouch) {
        if (!root.active || root.overHandle(pos))
            return
        root.touchMode = fromTouch
        if (!root.insideClip(root.toCanvas(pos))) {
            root.commit()
            return
        }
        const hit = root.hitAt(pos)
        if (count >= 3) {
            proxy.selectAll()
        } else if (count === 2) {
            const w = EditorState.inlineWordAt(hit)
            proxy.select(w.start, w.end)
        } else {
            root.moveCaret(hit, extend)
        }
        proxy.forceActiveFocus()
        if (root.touchMode)
            Qt.inputMethod.show()
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) !== 0
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0
        const composing = proxy.preeditText !== ""
        switch (event.key) {
        case Qt.Key_Escape:
            root.cancel()
            event.accepted = true
            break
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (ctrl) {
                root.commit()
                event.accepted = true
            }
            break
        case Qt.Key_Up:
        case Qt.Key_Down:
            if (!ctrl && !composing) {
                root.flush()
                root.moveCaret(EditorState.inlineMoveCaretLines(proxy.cursorPosition,
                                                                event.key === Qt.Key_Up ? -1 : 1),
                               shift)
                event.accepted = true
            }
            break
        case Qt.Key_Home:
        case Qt.Key_End:
            if (!ctrl && !composing) {
                root.flush()
                root.moveCaret(EditorState.inlineLineEdge(proxy.cursorPosition,
                                                          event.key === Qt.Key_End), shift)
                event.accepted = true
            }
            break
        }
    }

    Component.onDestruction: {
        if (root.active)
            EditorState.endInlineTextEdit(true)
    }

    Connections {
        target: EditorState
        function onInlineEditGeometryChanged() { root.geometryRevision++ }
        function onPlayingChanged() {
            if (EditorState.playing)
                root.commit()
        }
        function onPlayheadSecondsChanged() { root.commit() }
        function onSelectionChanged() {
            if (root.active && (EditorState.selectedTrack !== root.editTrack
                                || EditorState.selectedClip !== root.editClip))
                root.commit()
        }
        function onInlineTextEditingChanged() {
            // Ended from outside: nothing left to push to.
            if (root.active && !EditorState.inlineTextEditing) {
                root.active = false
                root._ready = false
                proxy.focus = false
                Qt.inputMethod.hide()
            }
        }
    }

    Item {
        id: noHit
        width: 0
        height: 0
    }

    // Never draws and never takes the pointer. It sits on the compositor's caret so the input
    // method's candidate window and the soft keyboard's cursor anchor land where the text is.
    TextEdit {
        id: proxy
        width: 1
        x: root.caretTopLeft.x - cursorRectangle.x
        y: root.caretTopLeft.y - cursorRectangle.y
        opacity: 0
        containmentMask: noHit
        textFormat: TextEdit.PlainText
        wrapMode: TextEdit.NoWrap
        inputMethodHints: Qt.ImhNone
        color: "transparent"
        selectionColor: "transparent"
        selectedTextColor: "transparent"
        cursorDelegate: Item { }
        selectByMouse: false
        persistentSelection: true
        activeFocusOnPress: false
        font.pixelSize: Math.max(8, Math.round(root.caretHeight))

        onTextChanged: root.markDirty()
        onCursorPositionChanged: root.markDirty()
        onSelectionStartChanged: root.markDirty()
        onSelectionEndChanged: root.markDirty()
        onPreeditTextChanged: root.markDirty()

        onActiveFocusChanged: {
            if (!activeFocus && root.active && !root._starting)
                root.commit()
        }

        Keys.onPressed: event => root.handleKey(event)
        // Escape and Ctrl+Enter would otherwise go to the app's own shortcuts.
        Keys.onShortcutOverride: event => {
            const ctrl = (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier)) !== 0
            if (event.key === Qt.Key_Escape
                    || (ctrl && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)))
                event.accepted = true
        }
    }

    Item {
        id: pointerLayer
        anchors.fill: parent

        HoverHandler {
            acceptedDevices: PointerDevice.Mouse
            cursorShape: Qt.IBeamCursor
        }

        TapHandler {
            id: plainTap
            acceptedModifiers: Qt.NoModifier
            onTapped: eventPoint => root.handleTap(
                          eventPoint.position, plainTap.tapCount, false,
                          eventPoint.device.type === PointerDevice.TouchScreen)
        }

        TapHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            acceptedModifiers: Qt.ShiftModifier
            onTapped: eventPoint => root.handleTap(eventPoint.position, 1, true, false)
        }

        TapHandler {
            acceptedDevices: PointerDevice.TouchScreen
            onLongPressed: {
                if (root.overHandle(point.position))
                    return
                root.touchMode = true
                const hit = root.hitAt(point.position)
                const w = EditorState.inlineWordAt(hit)
                proxy.select(w.start, w.end)
                proxy.forceActiveFocus()
                Qt.inputMethod.show()
            }
        }

        DragHandler {
            id: mouseSelect
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            acceptedButtons: Qt.LeftButton
            acceptedModifiers: Qt.NoModifier
            property int anchorPos: 0
            onActiveChanged: {
                if (active) {
                    root.touchMode = false
                    anchorPos = root.hitAt(centroid.pressPosition)
                }
            }
            onCentroidChanged: {
                if (active)
                    proxy.select(anchorPos, root.hitAt(centroid.position))
            }
        }
    }

    component Handle: Item {
        id: handle

        // "caret", "start" or "end": which way the teardrop's point faces.
        property string kind: "caret"
        property point tip

        signal grabbed()
        signal moved(point pos)

        width: root.handleTouch
        height: root.handleTouch
        x: tip.x - width / 2
        y: tip.y

        Rectangle {
            width: root.handleSize
            height: root.handleSize
            x: (handle.width - width) / 2
            y: width * (Math.SQRT2 - 1) / 2 + 2
            radius: width / 2
            topLeftRadius: handle.kind === "start" ? radius : 0
            topRightRadius: handle.kind === "start" ? 0 : radius
            rotation: handle.kind === "start" ? -45 : 45
            color: Theme.primary
        }

        DragHandler {
            id: drag
            target: null
            property point grab: Qt.point(0, 0)

            function scenePoint() {
                return root.mapFromItem(null, centroid.scenePosition.x, centroid.scenePosition.y)
            }

            onActiveChanged: {
                if (!active)
                    return
                const p = drag.scenePoint()
                drag.grab = Qt.point(p.x - handle.tip.x, p.y - handle.tip.y)
                handle.grabbed()
            }
            onCentroidChanged: {
                if (!active)
                    return
                const p = drag.scenePoint()
                // Hit-tested at the middle of the line the finger's tip points at.
                handle.moved(Qt.point(p.x - drag.grab.x, p.y - drag.grab.y - root.caretHeight / 2))
            }
        }
    }

    Handle {
        id: caretHandle
        kind: "caret"
        tip: root.caretTip
        visible: root.active && root.touchMode && root.hasCaret && proxy.preeditText === ""
                 && !root.hasSelection
        onMoved: pos => root.moveCaret(root.hitAt(pos), false)
    }

    property int _rangeAnchor: 0

    Handle {
        id: startHandle
        kind: "start"
        tip: root.selectionStartTip
        visible: root.active && root.touchMode && root.hasSelection && proxy.preeditText === ""
        onGrabbed: root._rangeAnchor = Math.max(proxy.selectionStart, proxy.selectionEnd)
        onMoved: pos => proxy.select(root._rangeAnchor,
                                     Math.min(root.hitAt(pos), root._rangeAnchor - 1))
    }

    Handle {
        id: endHandle
        kind: "end"
        tip: root.selectionEndTip
        visible: root.active && root.touchMode && root.hasSelection && proxy.preeditText === ""
        onGrabbed: root._rangeAnchor = Math.min(proxy.selectionStart, proxy.selectionEnd)
        onMoved: pos => proxy.select(root._rangeAnchor,
                                     Math.min(proxy.length, Math.max(root.hitAt(pos), root._rangeAnchor + 1)))
    }
}
