import QtQuick
import Drift

PanelFrame {
    id: root

    readonly property var clipData: EditorState.selectedClipData
    readonly property bool isSubtitle: (clipData?.kind ?? "") === "subtitle"
    readonly property bool captionTargetReady: {
        const kind = clipData?.kind ?? ""
        return kind === "video" || kind === "audio"
    }
    readonly property bool canGenerate: captionTargetReady && Addons.hasKind("whisper-model")
                                        && Addons.runtimeAvailable() && !EditorState.subtitleGenerating

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Subtitles")
    }

    SubtitleEditor {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.isSubtitle
        clip: root.isSubtitle ? root.clipData : null
    }

    EmptyState {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        visible: !root.isSubtitle
        glyph: Theme.icons.captions
        title: qsTr("Select a subtitle clip, or generate subtitles")
        actionText: root.canGenerate ? qsTr("Generate subtitles") : ""
        onActionTriggered: EditorState.generateSubtitlesForSelection()
    }
}
