import QtQuick
import QtQuick.Controls.Basic
import Drift
import QtQuick.Window

// --- Centre: global search -------------------------------------------
Rectangle {
    id: searchBox
    signal exportRequested()
    signal downloadsRequested()
    signal languageRequested()
    signal videoSizeRequested()
    signal searchFinished()
    function focusField() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }
    function dismiss() {
        searchInput.text = ""
        searchPopup.close()
        searchInput.focus = false
    }
    implicitHeight: Theme.controlHeight
    radius: height / 2
    color: Theme.panelAccent
    border.width: searchInput.activeFocus ? Theme.borderWidthFocus : 0
    border.color: Theme.focusRing

    IconGlyph {
        id: searchLens
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.search
        iconSize: Theme.iconSizeMd
        iconColor: Theme.mutedForeground
    }

    TextField {
        id: searchInput
        anchors.left: searchLens.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingMd
        anchors.rightMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        background: null
        leftPadding: 0
        rightPadding: 0
        color: Theme.panelForeground
        placeholderText: {
            const keys = EditorState.shortcutFor("search")
            return keys.length > 0 ? qsTr("Search  %1").arg(Theme.shortcutDisplay(keys))
                                   : qsTr("Search")
        }
        placeholderTextColor: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        selectByMouse: true
        selectedTextColor: Theme.primaryForeground
        selectionColor: Theme.primary

        onTextEdited: searchPopup.search(text)
        onActiveFocusChanged: if (activeFocus && text.trim().length > 0) searchPopup.search(text)

        // The popup never takes focus, so the field drives it.
        Keys.onUpPressed: (event) => { searchPopup.moveHighlight(-1); event.accepted = true }
        Keys.onDownPressed: (event) => { searchPopup.moveHighlight(1); event.accepted = true }
        Keys.onReturnPressed: (event) => { searchPopup.activate(searchPopup.highlightIndex); event.accepted = true }
        Keys.onEnterPressed: (event) => { searchPopup.activate(searchPopup.highlightIndex); event.accepted = true }
        Keys.onEscapePressed: (event) => { searchBox.searchFinished(); event.accepted = true }
    }

    GlobalSearchPopup {
        id: searchPopup
        y: searchBox.height + Theme.spacingMd
        x: (searchBox.width - width) / 2
        width: Math.max(searchBox.width, 480)
        headerCommands: [
            { label: qsTr("Export video"), keywords: "render save mp4", run: () => searchBox.exportRequested() },
            { label: qsTr("Downloads"), keywords: "download link", run: () => searchBox.downloadsRequested() },
            { label: qsTr("Language…"), keywords: "translate locale", run: () => searchBox.languageRequested() },
            { label: qsTr("Video size and layout"), keywords: "canvas resolution aspect ratio", run: () => searchBox.videoSizeRequested() },
            { label: qsTr("Switch to mobile layout…"), keywords: "phone shell", run: () => Window.window.switchShell("mobile") },
        ]
        onFinished: searchBox.searchFinished()
    }
}
