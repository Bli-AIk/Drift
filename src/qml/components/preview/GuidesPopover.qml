import QtQuick
import QtQuick.Controls.Basic
import Drift

// Guide sets and their items: which sets show, the library of custom sets, and
// per-item position, colour, opacity and lock. Built-in sets and sets that only
// came with the project are read-only here.
Popup {
    id: root

    property string selectedId: ""
    readonly property var sets: EditorState.guideSets
    readonly property var selected: {
        for (let i = 0; i < sets.length; ++i) {
            if (sets[i].id === selectedId)
                return sets[i]
        }
        return null
    }
    readonly property bool editable: selected !== null && selected.inLibrary

    width: Theme.dialogWidthSm
    padding: Theme.spacingMd
    // Not modal, and pressing the parent button does not count as outside, so that
    // button can toggle the popover instead of closing and reopening it.
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    onAboutToShow: {
        if (selected)
            return
        const active = sets.filter(s => s.active)
        selectedId = active.length > 0 ? active[0].id : (sets.length > 0 ? sets[0].id : "")
    }

    background: Rectangle {
        color: Theme.c.guidesPopover.background
        border.width: Theme.c.guidesPopover.borderWidth
        border.color: Theme.c.guidesPopover.border
        radius: Theme.c.guidesPopover.radius
    }

    contentItem: Column {
        spacing: Theme.spacingXs

        ThemedSwitch {
            width: parent.width
            text: qsTr("Show guides")
            checked: EditorState.preview.guidesEnabled
            onToggled: EditorState.preview.guidesEnabled = checked
        }

        GuidesPopoverSectionLabel { text: qsTr("Guide sets") }

        Flickable {
            width: parent.width
            height: Math.min(contentHeight, (Theme.controlHeight + Theme.spacingXs) * 6)
            contentHeight: setColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}

            Column {
                id: setColumn
                width: parent.width
                spacing: 0

                Repeater {
                    model: root.sets

                    GuidesPopoverSetRow {
                        selectedId: root.selectedId
                        rowWidth: setColumn.width
                        onPicked: id => root.selectedId = id
                    }
                }
            }
        }

        Row {
            spacing: 0

            IconButton {
                glyph: Theme.icons.plus
                tooltip: qsTr("New guide set")
                onClicked: root.selectedId = EditorState.createGuideSet("")
            }
            IconButton {
                glyph: Theme.icons.copyPlus
                tooltip: qsTr("Duplicate set")
                enabled: root.selected !== null
                onClicked: root.selectedId = EditorState.duplicateGuideSet(root.selectedId)
            }
            IconButton {
                glyph: Theme.icons.download
                tooltip: qsTr("Save to my guide sets")
                visible: root.selected !== null && !root.selected.builtIn && !root.selected.inLibrary
                onClicked: EditorState.saveGuideSetToLibrary(root.selectedId)
            }
            IconButton {
                glyph: Theme.icons.trash
                tooltip: qsTr("Delete set")
                enabled: root.editable
                onClicked: {
                    EditorState.deleteGuideSet(root.selectedId)
                    root.selectedId = ""
                }
            }
        }

        GuidesPopoverDivider {
            visible: root.selected !== null
        }

        ThemedTextField {
            id: nameField
            width: parent.width
            visible: root.editable
            placeholderText: qsTr("Set name")
            Binding on text {
                when: !nameField.activeFocus
                value: root.selected ? root.selected.name : ""
            }
            onEditingFinished: EditorState.renameGuideSet(root.selectedId, text)
        }

        ThemedButton {
            visible: root.editable
            glyph: Theme.icons.pencil
            text: qsTr("Edit on preview")
            onClicked: {
                EditorState.preview.guideEditSetId = root.selectedId
                root.close()
            }
        }

        GuidesPopoverReadOnlyNote {
            selected: root.selected
            visible: root.selected !== null && !root.editable
        }

        Flickable {
            width: parent.width
            height: Math.min(contentHeight, 320)
            visible: root.selected !== null
            contentHeight: itemColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: AppScrollBar {}

            Column {
                id: itemColumn
                width: parent.width
                spacing: Theme.spacingLg

                Repeater {
                    // A count, not the list: rows stay alive while their item's values
                    // change, so a dragged slider or focused field is not rebuilt under the user.
                    model: root.selected ? root.selected.items.length : 0

                    GuidesPopoverItemRow {
                        items: root.selected.items
                        setId: root.selectedId
                        editable: root.editable
                    }
                }
            }
        }

        Flow {
            width: parent.width
            spacing: Theme.spacingSm
            topPadding: Theme.spacingSm
            visible: root.editable

            Repeater {
                model: [
                    { kind: "v", label: qsTr("Vertical") },
                    { kind: "h", label: qsTr("Horizontal") },
                    { kind: "rect", label: qsTr("Margins") },
                    { kind: "aspect", label: qsTr("Frame") }
                ]
                ThemedButton {
                    required property var modelData
                    glyph: Theme.icons.plus
                    text: modelData.label
                    tooltip: qsTr("Add a guide")
                    onClicked: EditorState.addGuideItem(root.selectedId, modelData.kind)
                }
            }
        }
    }
}
