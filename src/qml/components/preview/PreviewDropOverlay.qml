import QtQuick
import QtQuick.Window
import Drift

// The preview as a drop target. Sits exactly over the canvas rect, turns a point on it into canvas
// pixels, and shows what a drop there would do: a frame around the whole canvas for something that
// lands as a new overlay, or the outline of the clip an effect or mask would go onto. The decision
// itself is AppController::planPreviewDrop, the same one the drop makes.
Item {
    id: root

    property var plan: null
    property bool hoveringExternalFiles: false
    readonly property bool showsCanvas: hoveringExternalFiles || (!!plan && plan.accepted && plan.mode === "canvas")
    readonly property bool showsClip: !!plan && plan.accepted && plan.mode === "clip"

    function toCanvas(localX, localY) {
        return Qt.point(localX / Math.max(1, width) * EditorState.projectFile.projectWidth(),
                        localY / Math.max(1, height) * EditorState.projectFile.projectHeight())
    }

    function containsLocal(localX, localY) {
        return localX >= 0 && localY >= 0 && localX <= width && localY <= height
    }

    function hover(kind, payload, localX, localY) {
        if (!containsLocal(localX, localY)) {
            clear()
            return false
        }
        const p = toCanvas(localX, localY)
        plan = EditorState.preview.planDrop(kind, String(payload), p.x, p.y)
        return plan.accepted
    }

    // File-manager drags have no library index until import and probing finish.
    // Show the canvas as the landing target for visual media in the meantime.
    function hoverUrls(urls, localX, localY) {
        clear()
        if (!containsLocal(localX, localY))
            return false
        if (!urls || urls.length === 0) {
            hoveringExternalFiles = true // Some platforms reveal URLs only on drop.
            return true
        }
        for (let i = 0; i < urls.length; ++i) {
            const kind = AssetLibrary.provisionalKindForUrl(urls[i])
            if (kind === "video" || kind === "image") {
                hoveringExternalFiles = true
                return true
            }
        }
        return false
    }

    function drop(kind, payload, label, localX, localY, onFinished) {
        clear()
        if (!containsLocal(localX, localY)) {
            if (onFinished)
                onFinished(false)
            return false
        }
        const p = toCanvas(localX, localY)
        const run = function() {
            const result = EditorState.preview.dropAsset(kind, String(payload), label || "", p.x, p.y)
            if (!result.accepted && result.message)
                Toasts.info(result.message)
            if (onFinished)
                onFinished(result.accepted)
        }
        // Media goes through the same import checks a timeline drop does.
        if (kind === "media" && ShellBridge.main && ShellBridge.main.configureAndAddAsset)
            ShellBridge.main.configureAndAddAsset(Number(payload), run)
        else
            run()
        return true
    }

    function dropUrls(urls, localX, localY) {
        clear()
        if (!containsLocal(localX, localY) || !urls || urls.length === 0)
            return false

        // Import first, then wait for metadata just like the timeline's external drop.
        // Each file gets its own new track in the preview, in the original drop order.
        const started = MediaImport.importUrls(urls, true, function(added) {
            if (added <= 0)
                return
            const firstIndex = AssetLibrary.count - added
            function placeNext(offset) {
                if (offset >= added)
                    return
                root.drop("media", firstIndex + offset, "", localX, localY,
                          function() { placeNext(offset + 1) })
            }
            placeNext(0)
        })
        return started
    }

    function clear() {
        plan = null
        hoveringExternalFiles = false
    }

    PreviewDropCanvasFrame {
        visible: root.showsCanvas
    }

    PreviewDropClipFrame {
        readonly property real sx: root.width / Math.max(1, EditorState.projectFile.projectWidth())
        readonly property real sy: root.height / Math.max(1, EditorState.projectFile.projectHeight())
        visible: root.showsClip
        x: root.showsClip ? root.plan.x * sx : 0
        y: root.showsClip ? root.plan.y * sy : 0
        width: root.showsClip ? root.plan.width * sx : 0
        height: root.showsClip ? root.plan.height * sy : 0
        rotation: root.showsClip ? root.plan.rotation : 0
    }
}
