import QtQuick
import Drift

PanelFrame {
    id: root

    // Set by PanelPool. The panel owns EditorState.assetPreview only while it is on screen.
    property bool shown: false
    property string loadedId: ""

    readonly property var selectedIds: ShellBridge.main?.assetsPanel?.selectedMediaAssetIds ?? []

    function openAsset(index) {
        if (ShellBridge.main?.mediaPreviewWindowOpen)
            return
        view.openFor(index)
        root.loadedId = view.assetId
    }

    function release() {
        if (root.loadedId.length === 0)
            return
        view.release()
        root.loadedId = ""
    }

    function followSelection() {
        if (!root.shown || view.saving)
            return
        if (root.loadedId.length > 0 && AssetLibrary.indexOfId(root.loadedId) < 0)
            root.release()
        if (root.selectedIds.length !== 1 || root.selectedIds[0] === root.loadedId)
            return
        const index = AssetLibrary.indexOfId(root.selectedIds[0])
        if (index >= 0)
            root.openAsset(index)
    }

    function reload() {
        const index = root.loadedId.length > 0 ? AssetLibrary.indexOfId(root.loadedId) : -1
        if (index < 0)
            root.release()
        else
            view.openFor(index)
    }

    onShownChanged: {
        if (root.shown)
            root.followSelection()
        else
            root.release()
    }
    onSelectedIdsChanged: root.followSelection()

    Connections {
        target: EditorState
        function onPlayingChanged() {
            if (EditorState.playing && EditorState.assetPreview.playing)
                EditorState.assetPreview.pause()
        }
    }

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: view.assetName.length > 0 && root.loadedId.length > 0
               ? qsTr("Source: %1").arg(view.assetName) : qsTr("Source Viewer")
    }

    MediaPreviewView {
        id: view
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.loadedId.length > 0
        shortcutsEnabled: false
        onCloseRequested: root.reload()
    }

    EmptyState {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        visible: root.loadedId.length === 0
        glyph: Theme.icons.play
        title: qsTr("Select a clip in the media bin to preview it here.")
    }
}
