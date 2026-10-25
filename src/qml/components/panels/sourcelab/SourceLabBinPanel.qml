pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Drift

PanelFrame {
    id: root

    property bool shown: false
    property string filter: "all"
    property string kindFilter: ""
    property int refreshTick: 0

    readonly property var lab: EditorState.sourceLab
    readonly property string query: search.text.trim().toLowerCase()
    readonly property bool empty: root.sources.length === 0
    readonly property var sources: {
        void root.refreshTick
        void AssetLibrary.count
        const out = []
        for (let i = 0; i < AssetLibrary.count; ++i) {
            const asset = AssetLibrary.assetAt(i)
            if (asset.kind === "video" || asset.kind === "audio" || asset.kind === "image")
                out.push(asset)
        }
        return out
    }
    readonly property var items: {
        const q = root.query
        return root.sources.filter(a => {
            if (root.kindFilter.length > 0 && a.kind !== root.kindFilter)
                return false
            if (q.length > 0 && a.name.toLowerCase().indexOf(q) < 0)
                return false
            switch (root.filter) {
            case "favorites": return a.rating > 0 || a.favoriteRangeCount > 0
            case "ranges": return a.rangeCount > 0
            case "hideRejected": return a.rating >= 0
            }
            return true
        })
    }

    function loadAt(index) {
        if (index < 0 || index >= root.items.length)
            return
        list.currentIndex = index
        list.positionViewAtIndex(index, ListView.Contain)
        // Off the search field, so Space and J/K/L reach the editor shortcuts.
        list.forceActiveFocus()
        root.lab.load(root.items[index].id)
    }

    function step(delta) {
        const at = root.items.findIndex(a => a.id === root.lab.currentAssetId)
        root.loadAt(at < 0 ? 0 : Math.max(0, Math.min(root.items.length - 1, at + delta)))
    }

    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: root.refreshTick++
    }

    Connections {
        target: AssetLibrary
        function onAssetCardChanged() { refreshTimer.restart() }
        function onDataChanged() { refreshTimer.restart() }
    }

    Connections {
        target: EditorState
        function onUndoStackChanged() { refreshTimer.restart() }
    }

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Sources")

        AssetsPanelImportSplit {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            importing: AssetLibrary.importing || EditorState.bin.importingFolder
            showCollect: false
            onImportFilesRequested: {
                const urls = FileDialogs.openFiles(qsTr("Import Media"),
                                                   [AssetLibrary.mediaNameFilter(), qsTr("All Files (*)")])
                MediaImport.importUrls(urls, false)
            }
            onImportFolderRequested: {
                const url = FileDialogs.openDirectory(qsTr("Import Folder"))
                if (!url || url.toString() === "")
                    return
                if (!EditorState.bin.importFolder(url))
                    Toasts.error(qsTr("Couldn’t import that folder."))
            }
        }
    }

    ThemedTextField {
        id: search
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.pagePadding
        visible: !root.empty
        placeholderText: qsTr("Search media")
        font.family: Theme.fontFamily
    }

    SourceLabBinFilterRow {
        id: filterRow
        anchors.top: search.bottom
        anchors.topMargin: Theme.spacingSm
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.pagePadding
        anchors.rightMargin: Theme.pagePadding
        visible: !root.empty
        height: visible ? implicitHeight : 0
        filter: root.filter
        kind: root.kindFilter
        onFilterChanged: root.filter = filter
        onKindChanged: root.kindFilter = kind
    }

    ListView {
        id: list
        anchors.top: filterRow.bottom
        anchors.topMargin: Theme.spacingSm
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingMd
        anchors.rightMargin: Theme.spacingMd
        visible: root.items.length > 0
        clip: true
        spacing: 2
        model: root.items
        activeFocusOnTab: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AppScrollBar { }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up)
                root.step(-1)
            else if (event.key === Qt.Key_Down)
                root.step(1)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                root.loadAt(Math.max(0, root.items.findIndex(a => a.id === root.lab.currentAssetId)))
            else
                return
            event.accepted = true
        }

        delegate: SourceLabBinRow {
            required property var modelData
            required property int index
            width: ListView.view.width
            asset: modelData
            current: modelData.id === root.lab.currentAssetId
            onPressed: {
                list.forceActiveFocus()
                root.loadAt(index)
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        width: parent.width
        visible: root.empty
        compact: true
        glyph: Theme.icons.film
        title: qsTr("No media yet")
        hint: qsTr("Import video, audio or image files to start.")
    }

    EmptyState {
        anchors.centerIn: parent
        width: parent.width
        visible: !root.empty && root.items.length === 0
        compact: true
        glyph: Theme.icons.search
        title: qsTr("Nothing matches")
        hint: qsTr("Try a different name or filter.")
    }
}
