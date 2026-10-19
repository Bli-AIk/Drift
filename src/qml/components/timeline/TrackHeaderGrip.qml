import QtQuick
import Drift

// Reorder affordance. The drag itself covers the whole header; this is the glyph and its tip.
IconGlyph {
    id: grip

    property bool shown: true
    property bool compact: false
    property bool hot: false
    property bool dragging: false
    property bool headerHovered: false
    property real centerOffset: 0

    visible: shown
    anchors.left: parent.left
    anchors.leftMargin: compact ? 4 : 8
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: centerOffset
    glyph: Theme.icons.gripVertical
    iconSize: compact ? 12 : 14
    iconColor: hot || dragging ? Theme.c.trackHeaderGrip.foreground : Theme.c.trackHeaderGrip.foregroundMuted

    Behavior on iconColor {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    ThemedToolTip {
        visible: grip.headerHovered && !grip.dragging
        text: qsTr("Drag the header to reorder this track")
    }

    // Hover affordance only — the drag lives on the whole header
    // row, so the grab target is not a 14px icon.
    HoverHandler { id: trackDragMouse }

    readonly property bool hovered: trackDragMouse.hovered
}
