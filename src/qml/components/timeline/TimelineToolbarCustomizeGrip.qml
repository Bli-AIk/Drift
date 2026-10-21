import QtQuick
import Drift

// Drag handle that reorders a customize row as the pointer crosses other rows.
IconGlyph {
    id: gripGlyph

    property var customizer
    property var view
    property int rowIndex: -1
    readonly property bool pressed: grip.pressed

    glyph: Theme.icons.gripVertical
    iconSize: Theme.iconSizeMd
    iconColor: Theme.c.timelineToolbarCustomizeGrip.icon

    // Moves the row live as the pointer crosses other rows; the model
    // move keeps this delegate, so the press survives it.
    MouseArea {
        id: grip
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        preventStealing: true
        onPositionChanged: (mouse) => {
            if (!pressed)
                return
            const p = mapToItem(gripGlyph.view.contentItem, mouse.x, mouse.y)
            const target = gripGlyph.view.indexAt(1, p.y)
            if (target >= 0)
                gripGlyph.customizer.moveEntry(gripGlyph.rowIndex, target)
        }
    }
}
