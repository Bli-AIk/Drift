import QtQuick
import QtQuick.Controls.Basic
import Drift

// Arranges the timeline toolbar: one list where everything above the "More menu" divider
// is a toolbar button and everything below it goes in the More menu, both in list order.
ThemedDialog {
    id: root

    // The TimelineToolbar being customised; supplies action metadata, defaults and layout.
    property var toolbar

    title: qsTr("Customize timeline toolbar")
    acceptText: qsTr("Save")
    preferredWidth: Theme.dialogWidthSm

    readonly property real rowHeight: 34

    ListModel { id: entries }

    function load(toolbarItems, menuItems) {
        entries.clear()
        for (const id of toolbarItems)
            entries.append({ "itemId": id })
        entries.append({ "itemId": "divider" })
        for (const id of menuItems)
            entries.append({ "itemId": id })
    }

    function dividerIndex() {
        for (var i = 0; i < entries.count; i++) {
            if (entries.get(i).itemId === "divider")
                return i
        }
        return entries.count
    }

    function moveEntry(from, to) {
        if (to < 0 || to >= entries.count || to === from)
            return
        entries.move(from, to, 1)
    }

    onOpened: load(toolbar.layout.toolbar, toolbar.layout.menu)

    onAccepted: {
        const toolbarItems = []
        const menuItems = []
        const split = dividerIndex()
        for (var i = 0; i < entries.count; i++) {
            const id = entries.get(i).itemId
            if (i < split)
                toolbarItems.push(id)
            else if (i > split)
                menuItems.push(id)
        }
        EditorState.preferences.setTimelineToolbarLayout(toolbarItems, menuItems)
    }

    contentItem: Column {
        width: parent ? parent.width : Theme.dialogWidthSm
        spacing: Theme.spacingMd

        ThemedLabel {
            width: parent.width
            wrapMode: Text.WordWrap
            text: qsTr("Drag items to reorder them. Items above the divider are toolbar buttons; the rest are in the More menu.")
        }

        Row {
            spacing: Theme.spacingMd

            ThemedButton {
                text: qsTr("Add separator")
                onClicked: entries.insert(root.dividerIndex(), { "itemId": "separator" })
            }
            ThemedButton {
                text: qsTr("Reset to defaults")
                onClicked: root.load(root.toolbar.defaultToolbarItems, root.toolbar.defaultMenuItems)
            }
        }

        ListView {
            id: list
            width: parent.width
            height: Math.min(contentHeight, Math.max(root.rowHeight * 4,
                             root.availableContentHeight - 120))
            clip: true
            model: entries
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}

            moveDisplaced: Transition {
                NumberAnimation { properties: "y"; duration: Theme.durationFast; easing.type: Theme.easing }
            }

            delegate: TimelineToolbarCustomizeRow {
                dialog: root
                view: list
                entryModel: entries
            }
        }
    }
}
