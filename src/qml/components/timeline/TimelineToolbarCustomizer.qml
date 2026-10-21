import QtQuick
import QtQuick.Controls.Basic
import Drift

// Arranges the timeline toolbar: one list where everything above the "More menu" divider
// is a toolbar button and everything below it goes in the More menu, both in list order.
// The customize dialog saves on Save; Settings sets autoSave so each change is kept at once.
Column {
    id: root

    property bool autoSave: false
    property real listMaxHeight: 480
    readonly property real rowHeight: 34
    readonly property var actions: TimelineToolbarActions {}

    ListModel { id: entries }

    function load(toolbarItems, menuItems) {
        entries.clear()
        for (const id of toolbarItems)
            entries.append({ "itemId": id })
        entries.append({ "itemId": "divider" })
        for (const id of menuItems)
            entries.append({ "itemId": id })
    }

    function reload() {
        load(actions.layout.toolbar, actions.layout.menu)
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
        commit()
    }

    function addSeparator() {
        entries.insert(dividerIndex(), { "itemId": "separator" })
        commit()
    }

    function removeEntry(index) {
        entries.remove(index)
        commit()
    }

    function resetToDefaults() {
        load(actions.defaultToolbarItems, actions.defaultMenuItems)
        commit()
    }

    function commit() {
        if (autoSave)
            save()
    }

    function save() {
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

    Component.onCompleted: reload()
    onVisibleChanged: if (visible) reload()

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
            onClicked: root.addSeparator()
        }
        ThemedButton {
            text: qsTr("Reset to defaults")
            onClicked: root.resetToDefaults()
        }
    }

    ListView {
        id: list
        width: parent.width
        height: Math.min(contentHeight, Math.max(root.rowHeight * 4, root.listMaxHeight))
        clip: true
        model: entries
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AppScrollBar {}

        moveDisplaced: Transition {
            NumberAnimation { properties: "y"; duration: Theme.durationFast; easing.type: Theme.easing }
        }

        delegate: TimelineToolbarCustomizeRow {
            customizer: root
            view: list
            entryModel: entries
        }
    }
}
