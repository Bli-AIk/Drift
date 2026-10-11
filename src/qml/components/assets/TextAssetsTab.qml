import QtQuick
import QtQuick.Controls.Basic
import Drift
import ".."

// Text tab: click a style pack to drop a styled text clip on the timeline
// (placeholder copy + inline edit). Timed captions live under Subtitles.
// Styles the user saved from the properties Text tab sit behind the "My styles" chip.
Item {
    id: root

    // A clip landed on the timeline. The phone shell closes the sheet on this —
    // the thing you came for is behind it.
    signal added()

    property string section: "builtin"

    readonly property var presets: EditorState.textPresets()

    // A QVariantList from an invokable is not reactive, so the section is refreshed by poking
    // this counter from the controller's signal.
    property int userPresetsTick: 0
    readonly property var userPresets: {
        void root.userPresetsTick
        return EditorState.userTextPresets()
    }

    Connections {
        target: EditorState
        function onUserTextPresetsChanged() { root.userPresetsTick++ }
    }

    readonly property string styleFileFilter: qsTr("Drift text style (*.drifttextstyle)")

    function importStyle() {
        const url = FileDialogs.openFile(qsTr("Import text style"), [root.styleFileFilter])
        if (url.toString().length > 0) {
            EditorState.importUserTextPreset(url)
            root.section = "mine"
        }
    }

    function exportStyle(preset) {
        const url = FileDialogs.saveFile(qsTr("Export text style"), [root.styleFileFilter],
                                         preset.label, "drifttextstyle")
        if (url.toString().length > 0)
            EditorState.exportUserTextPreset(preset.id, url)
    }

    Item {
        id: toolbar
        width: parent.width
        height: Theme.pagePadding + Theme.controlHeight

        Row {
            x: Theme.pagePadding
            y: Theme.pagePadding
            height: Theme.controlHeight
            spacing: Theme.spacingSm

            ThemedChip {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Built-in")
                variant: "outline"
                selected: root.section === "builtin"
                onClicked: root.section = "builtin"
            }

            ThemedChip {
                anchors.verticalCenter: parent.verticalCenter
                text: root.userPresets.length > 0 ? qsTr("My styles · %1").arg(root.userPresets.length)
                                                  : qsTr("My styles")
                variant: "outline"
                selected: root.section === "mine"
                onClicked: root.section = "mine"
            }
        }

        IconButton {
            anchors.right: parent.right
            anchors.rightMargin: Theme.pagePadding
            y: Theme.pagePadding
            buttonSize: Theme.controlHeight
            glyph: Theme.icons.folderInput
            variant: "ghost"
            tooltip: qsTr("Import a text style…")
            onClicked: root.importStyle()
        }
    }

    // Built-in packs and the user's own styles are separate grids, switched from the toolbar.
    GridView {
        id: packGrid
        // As many columns as fit at the nominal card size, rounded, with the cards stretched or
        // squeezed a little to fill the row — a fixed card left a column's worth of empty space.
        readonly property int columnCount: Math.max(1, Math.round(width / (Theme.assetCardWidth + Theme.assetCardGap)))
        readonly property real cardSize: Math.floor(width / columnCount) - Theme.assetCardGap
        x: Theme.pagePadding
        y: toolbar.height + Theme.spacingSm
        width: parent.width - Theme.pagePadding * 2 + Theme.assetCardGap
        height: parent.height - y
        bottomMargin: Theme.spacing3xl
        clip: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        acceptedButtons: Theme.touchUi ? Qt.LeftButton : Qt.NoButton
        ScrollBar.vertical: AppScrollBar { }
        cellWidth: Math.floor(width / columnCount)
        cellHeight: Math.round(cardSize * 0.55) + Theme.spacingSm
                    + Math.ceil(labelMetrics.height) + Theme.assetCardGap
        visible: root.section === "builtin"
        model: root.presets

        delegate: Column {
            id: packCard
            required property var modelData
            width: packGrid.cardSize
            spacing: Theme.spacingSm

            opacity: packDrag.active ? 0.85 : 1
            scale: packDrag.active ? 1.04 : packDrag.pressed ? 0.97 : (packDrag.hovered ? 1.02 : 1.0)
            Behavior on scale {
                NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
            }

            TextStylePackThumb {
                width: parent.width
                height: Math.round(width * 0.55)
                presetId: packCard.modelData.id
                hovered: packDrag.hovered

                AssetDragSource {
                    id: packDrag
                    hasContextMenu: true
                    onContextMenuRequested: cardMenu.popup()
                    anchors.fill: parent
                    kind: "textStyle"
                    payload: packCard.modelData.id
                    label: packCard.modelData.label
                    glyph: Theme.icons.type
                    onTapped: {
                        EditorState.addTextClip("", -1, packCard.modelData.id)
                        root.added()
                    }
                }

                ThemedToolTip {
                    text: qsTr("%1 — click to add at the playhead, or drag to the timeline. Double-click it on the preview to edit.").arg(packCard.modelData.label)
                    visible: packDrag.hovered && !packDrag.active
                }

                ThemedContextMenu {
                    id: cardMenu

                    ThemedMenuItem {
                        text: qsTr("Add at playhead")
                        icon.name: Theme.icons.plus
                        onTriggered: packDrag.tapped()
                    }
                }
            }

            Text {
                width: parent.width
                text: packCard.modelData.label
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                color: packDrag.hovered ? Theme.panelForeground : Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs

                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }
        }
    }

    GridView {
        id: userGrid
        // As many columns as fit at the nominal card size, rounded, with the cards stretched or
        // squeezed a little to fill the row — a fixed card left a column's worth of empty space.
        readonly property int columnCount: Math.max(1, Math.round(width / (Theme.assetCardWidth + Theme.assetCardGap)))
        readonly property real cardSize: Math.floor(width / columnCount) - Theme.assetCardGap
        x: Theme.pagePadding
        y: toolbar.height + Theme.spacingSm
        width: parent.width - Theme.pagePadding * 2 + Theme.assetCardGap
        height: parent.height - y
        bottomMargin: Theme.spacing3xl
        clip: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        acceptedButtons: Theme.touchUi ? Qt.LeftButton : Qt.NoButton
        ScrollBar.vertical: AppScrollBar { }
        cellWidth: Math.floor(width / columnCount)
        cellHeight: Math.round(cardSize * 0.55) + Theme.spacingSm
                    + Math.ceil(labelMetrics.height) + Theme.assetCardGap
        visible: root.section === "mine" && root.userPresets.length > 0
        model: root.userPresets

        delegate: Column {
            id: userCard
            required property var modelData
            width: userGrid.cardSize
            spacing: Theme.spacingSm

            opacity: userDrag.active ? 0.85 : 1
            scale: userDrag.active ? 1.04 : userDrag.pressed ? 0.97 : (userDrag.hovered ? 1.02 : 1.0)
            Behavior on scale {
                NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
            }

            TextStylePackThumb {
                width: parent.width
                height: Math.round(width * 0.55)
                presetId: userCard.modelData.id
                hovered: userDrag.hovered

                AssetDragSource {
                    id: userDrag
                    anchors.fill: parent
                    kind: "textStyle"
                    payload: userCard.modelData.id
                    label: userCard.modelData.label
                    glyph: Theme.icons.type
                    hasContextMenu: true
                    onContextMenuRequested: cardMenu.popup()
                    onTapped: {
                        EditorState.addTextClip("", -1, userCard.modelData.id)
                        root.added()
                    }
                }

                ThemedToolTip {
                    text: qsTr("%1 — click to add at the playhead, or drag to the timeline. Double-click it on the preview to edit.").arg(userCard.modelData.label)
                    visible: userDrag.hovered && !userDrag.active
                }

                IconButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 2
                    visible: userDrag.hovered || cardMenu.visible
                    glyph: Theme.icons.ellipsis
                    variant: "ghost"
                    buttonSize: 20
                    iconSize: 12
                    tooltip: qsTr("Style options")
                    onClicked: cardMenu.popup()
                }

                ThemedContextMenu {
                    id: cardMenu

                    ThemedMenuItem {
                        text: qsTr("Rename…")
                        icon.name: Theme.icons.pencil
                        onTriggered: renameDialog.openFor(userCard.modelData)
                    }
                    ThemedMenuItem {
                        text: qsTr("Export…")
                        icon.name: Theme.icons.folderOutput
                        onTriggered: root.exportStyle(userCard.modelData)
                    }
                    ThemedMenuSeparator { }
                    ThemedMenuItem {
                        text: qsTr("Delete")
                        icon.name: Theme.icons.trash
                        onTriggered: deleteDialog.openFor(userCard.modelData)
                    }
                }
            }

            Text {
                width: parent.width
                text: userCard.modelData.label
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                color: userDrag.hovered ? Theme.panelForeground : Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs

                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }
        }
    }

    EmptyState {
        anchors.horizontalCenter: parent.horizontalCenter
        y: toolbar.height + Math.max(0, (parent.height - toolbar.height - height) / 2)
        width: Math.min(parent.width - Theme.spacing3xl, 260)
        visible: root.section === "mine" && root.userPresets.length === 0
        compact: true
        glyph: Theme.icons.type
        title: qsTr("No saved styles")
        hint: qsTr("Style some text, then use “Save style…” in the properties Text tab to keep it here.")
        actionText: qsTr("Import")
        onActionTriggered: root.importStyle()
    }

    NameDialog {
        id: renameDialog

        property string presetId: ""

        function openFor(preset) {
            presetId = preset.id
            openWith(qsTr("Rename text style"), preset.label)
        }

        onSubmitted: name => EditorState.renameUserTextPreset(renameDialog.presetId, name)
    }

    ThemedDialog {
        id: deleteDialog

        property string presetId: ""
        property string presetLabel: ""

        title: qsTr("Delete text style")
        acceptText: qsTr("Delete")
        acceptVariant: "destructive"
        preferredWidth: Theme.dialogWidthSm
        acceptOnReturn: false

        function openFor(preset) {
            presetId = preset.id
            presetLabel = preset.label
            open()
        }

        onAccepted: EditorState.deleteUserTextPreset(deleteDialog.presetId)

        contentItem: Text {
            width: parent ? parent.width : 320
            wrapMode: Text.WordWrap
            text: qsTr("Remove “%1” from your saved styles? Clips already using it keep their look.")
                      .arg(deleteDialog.presetLabel)
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }
    }
}