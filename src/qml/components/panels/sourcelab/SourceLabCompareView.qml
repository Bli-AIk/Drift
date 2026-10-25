import QtQuick
import QtMultimedia
import Drift

// The source picture with the crop editor, and the B side of the A/B compare. What B shows
// depends on the tool: the cropped picture, a restore model's output for the frame under the
// playhead, or a short rendered segment of the recipe played in step with A.
Rectangle {
    id: root

    // off | split | side | toggle
    property string mode: "off"
    property bool showB: false
    // crop | enhance | segment
    property string tool: "crop"
    property bool isImage: false
    property bool isAudio: false
    property string imagePath: ""
    property string assetId: ""
    property string segmentPath: ""
    property real segmentStart: 0
    property bool segmentStale: false
    property real splitFraction: 0.5

    readonly property var preview: EditorState.assetPreview
    readonly property var recipe: EditorState.sourceLab.recipe
    readonly property bool compareActive: root.mode !== "off" && !root.isAudio
    readonly property bool enhanceActive: root.compareActive && root.tool === "enhance" && root.assetId.length > 0
    readonly property bool enhanceBusy: root.restoreState.loading === true
    readonly property bool hasEnhanced: (root.restoreState.enhancedWidth ?? 0) > 0

    property int restoreRevision: 0
    readonly property var restoreState: {
        void root.restoreRevision
        return root.enhanceActive ? EditorState.restore.previewState() : ({})
    }

    readonly property real wipeX: root.splitFraction * root.width
    readonly property bool sideBySide: root.mode === "side"
    readonly property bool wipe: root.mode === "split"
    readonly property bool bShown: root.compareActive && (root.mode !== "toggle" || root.showB)
    readonly property bool aShown: !(root.mode === "toggle" && root.showB && root.compareActive)
    readonly property bool overlayShown: !root.isAudio && root.aShown
                                         && !(root.wipe && root.tool === "crop")

    function previewEnhance() {
        EditorState.restore.preview(root.assetId, root.recipe.decompressModel ?? "",
                                    root.recipe.upscaleModel ?? "")
    }

    function requestRestoreFrame() {
        if (root.enhanceActive)
            EditorState.restore.setPreviewFrame(root.assetId, root.preview.position)
    }

    // Segment B plays the recipe's result, so a source time maps through the speed change.
    function syncSegment() {
        if (!root.bShown || root.tool !== "segment" || root.segmentPath.length === 0)
            return
        const target = (root.preview.position - root.segmentStart) / (root.recipe.speed ?? 1) * 1000
        const inRange = target >= 0 && target <= segPlayer.duration
        segOut.visible = inRange
        if (!inRange) {
            if (segPlayer.playbackState === MediaPlayer.PlayingState)
                segPlayer.pause()
            return
        }
        const slack = root.preview.playing ? 250 : 15
        if (Math.abs(segPlayer.position - target) > slack)
            segPlayer.position = target
        if (root.preview.playing && segPlayer.playbackState !== MediaPlayer.PlayingState)
            segPlayer.play()
        else if (!root.preview.playing && segPlayer.playbackState === MediaPlayer.PlayingState)
            segPlayer.pause()
    }

    // No stage fill: the picture's own edges are the frame, so nothing outside reads as canvas.
    color: "transparent"
    clip: true

    onEnhanceActiveChanged: {
        if (root.enhanceActive)
            root.requestRestoreFrame()
        else
            EditorState.restore.endPreview()
    }
    Component.onDestruction: {
        if (root.enhanceActive)
            EditorState.restore.endPreview()
    }

    Connections {
        target: EditorState.restore
        function onPreviewChanged() {
            root.restoreRevision++
        }
    }

    Connections {
        target: root.preview
        function onPositionChanged() {
            root.syncSegment()
            if (root.enhanceActive && !root.preview.playing)
                restoreFrameTimer.restart()
        }
        function onPlayingChanged() {
            root.syncSegment()
        }
    }

    Timer {
        id: restoreFrameTimer
        interval: 200
        onTriggered: root.requestRestoreFrame()
    }

    onBShownChanged: root.syncSegment()
    onSegmentPathChanged: segmentSyncTimer.restart()
    Timer {
        id: segmentSyncTimer
        interval: 120
        onTriggered: root.syncSegment()
    }

    Item {
        id: aPane
        width: root.sideBySide && root.compareActive ? root.width / 2 : root.width
        height: root.height
        visible: root.aShown

        Image {
            id: aImage
            anchors.fill: parent
            visible: !root.isAudio
            fillMode: Image.PreserveAspectFit
            asynchronous: root.isImage
            cache: root.isImage
            source: {
                if (root.isImage)
                    return root.imagePath.length > 0 ? EditorState.imageUrl(root.imagePath) : ""
                return root.preview.active && !root.isAudio
                       ? "image://clippreview/frame?rev=" + root.preview.revision : ""
            }
        }

        MediaPreviewAudioPlaceholder {
            visible: root.isAudio
            anchors.centerIn: parent
            assetName: EditorState.sourceLab.name
        }

        SourceLabCropOverlay {
            anchors.fill: parent
            visible: root.overlayShown && aImage.paintedWidth > 0
            paintedWidth: aImage.paintedWidth
            paintedHeight: aImage.paintedHeight
        }

        SourceLabPaneLabel {
            visible: root.compareActive
            text: qsTr("A")
        }
    }

    Item {
        id: bHolder
        x: root.wipe ? root.wipeX : (root.sideBySide ? root.width / 2 : 0)
        width: root.wipe ? root.width - root.wipeX : (root.sideBySide ? root.width / 2 : root.width)
        height: root.height
        clip: true
        visible: root.bShown

        Item {
            id: bPane
            x: root.wipe ? -bHolder.x : 0
            width: root.wipe ? root.width : bHolder.width
            height: root.height

            Rectangle {
                anchors.fill: parent
                visible: root.wipe || root.mode === "toggle"
                // Hides A behind B's letterbox in the wipe and toggle views.
                color: Theme.c.panelFrame.background
            }

            Image {
                anchors.fill: parent
                visible: root.tool === "crop"
                fillMode: Image.PreserveAspectFit
                cache: false
                source: root.tool === "crop" ? aImage.source : ""
                sourceClipRect: Qt.rect((root.recipe.crop?.x ?? 0) * aImage.implicitWidth,
                                        (root.recipe.crop?.y ?? 0) * aImage.implicitHeight,
                                        (root.recipe.crop?.width ?? 1) * aImage.implicitWidth,
                                        (root.recipe.crop?.height ?? 1) * aImage.implicitHeight)
            }

            Image {
                anchors.fill: parent
                visible: root.tool === "enhance"
                fillMode: Image.PreserveAspectFit
                cache: false
                source: {
                    if (root.tool !== "enhance")
                        return ""
                    const state = root.restoreState
                    void root.restoreRevision
                    if ((state.enhancedWidth ?? 0) > 0)
                        return "image://segment/restore-enhanced?rev=" + state.revision
                    return (state.width ?? 0) > 0
                           ? "image://segment/restore-original?rev=" + state.revision : ""
                }
            }

            Item {
                anchors.fill: parent
                visible: root.tool === "segment"

                VideoOutput {
                    id: segOut
                    anchors.fill: parent
                    fillMode: VideoOutput.PreserveAspectFit
                }
                MediaPlayer {
                    id: segPlayer
                    videoOutput: segOut
                    source: root.segmentPath.length > 0 ? EditorState.fileUrl(root.segmentPath) : ""
                    onSourceChanged: if (source.toString().length > 0) pause()
                    onDurationChanged: root.syncSegment()
                }
            }

            ThemedLabel {
                anchors.centerIn: parent
                width: parent.width - Theme.spacingLg * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                tone: "default"
                visible: text.length > 0
                text: {
                    if (root.tool === "enhance")
                        return root.hasEnhanced ? "" : (root.enhanceBusy ? qsTr("Enhancing this frame...")
                                                                          : qsTr("Press Preview frame to see the enhanced picture."))
                    if (root.tool === "segment") {
                        if (EditorState.sourceLab.previewBusy)
                            return qsTr("Rendering preview...")
                        if (root.segmentPath.length === 0)
                            return qsTr("Press Render preview to see the result here.")
                        return root.segmentStale ? qsTr("The settings changed. Render the preview again.") : ""
                    }
                    return ""
                }
            }

            SourceLabPaneLabel {
                text: qsTr("B")
            }
        }
    }

    Item {
        id: wipeHandle
        visible: root.wipe && root.compareActive
        x: root.wipeX - width / 2
        width: Theme.touchUi ? 28 : 16
        height: root.height
        z: 5

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.c.sourceLabCompare.dividerWidth
            height: parent.height
            color: Theme.c.sourceLabCompare.divider
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SplitHCursor
            preventStealing: true
            onPositionChanged: (mouse) => {
                if (!pressed)
                    return
                const x = wipeHandle.x + mouse.x
                root.splitFraction = Math.max(0.02, Math.min(0.98, x / Math.max(1, root.width)))
            }
        }
    }

    Rectangle {
        x: root.width / 2 - width / 2
        visible: root.sideBySide && root.compareActive
        width: Theme.c.sourceLabCompare.dividerWidth
        height: root.height
        color: Theme.c.sourceLabCompare.divider
    }
}
