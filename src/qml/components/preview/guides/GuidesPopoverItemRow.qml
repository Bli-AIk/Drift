import QtQuick
import Drift

// One guide item: wires its fields to EditorState. The visuals live in the children.
Column {
    id: row

    required property int index
    required property var items
    required property string setId
    required property bool editable
    readonly property var item: items[index]

    function set(key, value) {
        EditorState.setGuideItemProperty(row.setId, row.item.id, key, value)
    }

    width: parent ? parent.width : 0
    spacing: Theme.spacingXs
    enabled: row.editable

    GuidesPopoverItemHeader {
        item: row.item
        editable: row.editable
        onLockToggled: row.set("locked", !row.item.locked)
        onRemoveRequested: EditorState.removeGuideItem(row.setId, row.item.id)
    }

    GuidesPopoverLinePosition {
        item: row.item
        onEdited: f => row.set("pos", f)
    }

    GuidesPopoverMarginFields {
        item: row.item
        onEdited: (key, fraction) => row.set(key, fraction)
    }

    GuidesPopoverAspectFields {
        item: row.item
        onWidthEdited: v => row.set("aspectW", v)
        onHeightEdited: v => row.set("aspectH", v)
    }

    GuidesPopoverColorRow {
        item: row.item
        onColorEdited: v => row.set("color", v)
        onOpacityEdited: v => row.set("opacity", v)
    }
}
