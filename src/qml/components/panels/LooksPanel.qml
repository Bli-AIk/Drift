pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift

PanelFrame {
    id: root

    property bool shown: false

    readonly property var colorState: EditorState.color
    readonly property var target: colorState.target
    readonly property bool hasTarget: !!target.hasTarget
    readonly property var params: target.params || ({})
    readonly property string currentLook: params.look || ""
    property string query: ""
    property var live: undefined
    property string pendingId: ""

    readonly property string favoritesId: "__favorites__"
    readonly property string mineId: "__mine__"
    property int favoritesTick: 0
    readonly property string trimmedQuery: query.trim()

    readonly property var categories: {
        const out = []
        const seen = {}
        const list = colorState.looks
        for (let i = 1; i < list.length; ++i) {
            if (list[i].userInstalled)
                continue
            const name = list[i].category || qsTr("Looks")
            if (!seen[name]) {
                seen[name] = true
                out.push({ id: name, label: name })
            }
        }
        return out
    }
    property string activeCategory: categories.length > 0 ? categories[0].id : mineId

    readonly property var visibleLooks: {
        void favoritesTick
        const q = trimmedQuery.toLowerCase()
        const list = colorState.looks
        const out = []
        if (q.length > 0) {
            for (let i = 1; i < list.length; ++i) {
                if (list[i].label.toLowerCase().indexOf(q) >= 0)
                    out.push(list[i])
            }
            return out
        }
        if (activeCategory === favoritesId) {
            for (let i = 1; i < list.length; ++i) {
                if (EditorState.isAssetFavorite("looks", list[i].id))
                    out.push(list[i])
            }
            return out
        }
        if (activeCategory === mineId) {
            for (let i = 1; i < list.length; ++i) {
                if (list[i].userInstalled)
                    out.push(list[i])
            }
            return out
        }
        if (list.length > 0)
            out.push(list[0])
        for (let i = 1; i < list.length; ++i) {
            if (!list[i].userInstalled && (list[i].category || qsTr("Looks")) === activeCategory)
                out.push(list[i])
        }
        return out
    }

    property var menuLook: ({})

    function importLooks() {
        const urls = FileDialogs.openFiles(qsTr("Import looks"), [qsTr("LUT files (*.cube)")])
        if (urls && urls.length > 0)
            colorState.importLooks(urls)
    }

    function syncActive() {
        const on = root.shown
        if (colorState.thumbnailsActive !== on)
            colorState.thumbnailsActive = on
        if (on)
            colorState.requestThumbnails()
    }

    onShownChanged: syncActive()
    Component.onCompleted: syncActive()
    Component.onDestruction: colorState.thumbnailsActive = false
    onTargetChanged: if (shown) colorState.requestThumbnails()

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("Looks")
    }

    Connections {
        target: EditorState
        function onAssetFavoritesChanged() {
            root.favoritesTick++
        }
    }

    readonly property bool nothingInstalled: colorState.looks.length <= 1

    Column {
        id: top
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        AssetSearchBar {
            id: search
            placeholderText: qsTr("Search looks")
            onTextChanged: root.query = text

            IconButton {
                glyph: Theme.icons.download
                variant: "ghost"
                buttonSize: Theme.controlHeight
                tooltip: qsTr("Import .cube looks")
                onClicked: root.importLooks()
            }
        }

        Item {
            width: 1
            height: Theme.spacingSm
        }

        AssetCategoryChips {
            id: categoryChips
            width: parent.width
            categories: root.categories
            activeCategory: root.activeCategory
            showMine: true
            mineLabel: qsTr("My Looks")
            searching: root.trimmedQuery.length > 0
            onCategoryActivated: categoryId => root.activeCategory = categoryId
        }

        Item {
            width: 1
            height: Theme.spacingSm
        }

        GradeSlider {
            x: Theme.pagePadding
            width: parent.width - Theme.pagePadding * 2
            enabled: root.hasTarget
            opacity: root.hasTarget ? 1 : 0.5
            label: qsTr("Look Intensity")
            from: 0
            to: 1
            defaultValue: 1
            bipolar: false
            value: root.live !== undefined ? root.live : (root.params.lookAmount ?? 1)
            onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
            onMoved: v => {
                root.live = v
                root.colorState.setParam("lookAmount", v)
            }
            onEnded: {
                root.colorState.commitEdit()
                root.live = undefined
            }
        }
    }

    FontMetrics {
        id: nameMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    GridView {
        id: grid
        readonly property int columnCount: Math.max(2, Math.round(width / 112))
        readonly property real cardSize: Math.floor(width / columnCount) - Theme.spacingMd
        anchors.top: top.bottom
        anchors.topMargin: Theme.spacingMd
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - Theme.pagePadding * 2 + Theme.spacingMd
        visible: root.visibleLooks.length > 0 && !root.nothingInstalled
        enabled: root.hasTarget
        opacity: root.hasTarget ? 1 : 0.5
        clip: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: cellHeight
        topMargin: 4
        bottomMargin: Theme.spacingLg
        cellWidth: Math.floor(width / columnCount)
        cellHeight: Math.round(cardSize * 9 / 16) + Theme.spacingXs + Math.ceil(nameMetrics.height)
                    + Theme.spacingMd
        model: root.visibleLooks
        ScrollBar.vertical: AppScrollBar { }

        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool current: root.currentLook === modelData.id
            readonly property real thumbWidth: grid.cardSize
            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                id: thumb
                width: card.thumbWidth
                height: Math.round(width * 9 / 16)
                radius: Theme.radiusMd
                color: Theme.panelSecondaryBg
                border.width: card.current ? 2 : 0
                border.color: Theme.primary
                clip: true

                Image {
                    anchors.fill: parent
                    anchors.margins: card.current ? 2 : 0
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: Math.min(card.thumbWidth, 160) * Screen.devicePixelRatio
                    source: root.colorState.thumbnailSerial > 0
                            ? "image://color/look/" + (card.modelData.id || "none")
                              + "?s=" + root.colorState.thumbnailSerial
                            : ""
                    opacity: status === Image.Ready ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                AssetFavoriteButton {
                    visible: card.modelData.id !== ""
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 3
                    tabId: "looks"
                    itemId: card.modelData.id
                }
            }

            Text {
                y: thumb.height + Theme.spacingXs
                width: card.thumbWidth
                elide: Text.ElideRight
                text: card.modelData.label
                color: card.current ? Theme.panelForeground : Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: root.colorState.setLook(card.modelData.id)
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: !!card.modelData.userInstalled
                onTapped: {
                    root.menuLook = card.modelData
                    lookMenu.popup()
                }
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                enabled: !!card.modelData.userInstalled
                longPressThreshold: 0.6
                gesturePolicy: TapHandler.DragThreshold
                onLongPressed: {
                    root.menuLook = card.modelData
                    lookMenu.popup()
                }
            }
        }
    }

    ThemedContextMenu {
        id: lookMenu
        ThemedMenuItem {
            text: qsTr("Rename…")
            icon.name: Theme.icons.pencil
            onTriggered: {
                root.pendingId = root.menuLook.id
                renameField.text = root.menuLook.label
                renameDialog.open()
            }
        }
        ThemedMenuItem {
            text: qsTr("Remove")
            icon.name: Theme.icons.trash
            onTriggered: root.colorState.removeLook(root.menuLook.id)
        }
    }

    Text {
        x: Theme.pagePadding
        y: grid.y + Theme.spacingMd
        width: parent.width - Theme.pagePadding * 2
        visible: root.visibleLooks.length === 0 && !root.nothingInstalled
                 && !(root.activeCategory === root.mineId && root.trimmedQuery.length === 0)
        text: root.trimmedQuery.length > 0
              ? qsTr("No looks match “%1”.").arg(root.trimmedQuery)
              : (root.activeCategory === root.favoritesId
                 ? qsTr("No favorites yet. Star looks to save them here.")
                 : qsTr("Nothing in this category."))
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        wrapMode: Text.WordWrap
    }

    EmptyState {
        anchors.horizontalCenter: parent.horizontalCenter
        y: grid.y + (grid.height - height) / 2
        width: Math.min(parent.width - Theme.spacing3xl, 260)
        visible: root.activeCategory === root.mineId && root.visibleLooks.length === 0
                 && root.trimmedQuery.length === 0 && !root.nothingInstalled
        compact: true
        glyph: Theme.icons.download
        title: qsTr("%1 is empty").arg(qsTr("My Looks"))
        hint: qsTr("Import a .cube file to add your own.")
        actionText: qsTr("Import")
        onActionTriggered: root.importLooks()
    }

    EmptyState {
        anchors.horizontalCenter: parent.horizontalCenter
        y: grid.y + (grid.height - height) / 2
        width: Math.min(parent.width - Theme.spacing3xl, 260)
        visible: root.nothingInstalled
        compact: true
        glyph: Theme.icons.sparkles
        title: qsTr("No looks")
        hint: qsTr("Download a free pack of ready-made looks, or import your own .cube files.")
        actionText: qsTr("Get free looks")
        onActionTriggered: ShellBridge.main.openAddonManager("looks")
    }

    EmptyState {
        anchors.centerIn: parent
        visible: !root.hasTarget
        glyph: Theme.icons.sparkles
        title: qsTr("Select a clip to try looks on it")
        compact: true
    }

    ThemedDialog {
        id: renameDialog
        title: qsTr("Rename look")
        acceptText: qsTr("Rename")
        onAccepted: {
            const name = renameField.text.trim()
            if (name.length > 0)
                root.colorState.renameLook(root.pendingId, name)
        }
        onOpened: renameField.forceActiveFocus()

        contentItem: ThemedTextField {
            id: renameField
        }
    }
}
