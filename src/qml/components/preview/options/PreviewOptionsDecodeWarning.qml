import QtQuick
import Drift
// The closed combo's warning, for a decoder that runs on the other GPU.
IconGlyph {
    id: glyph

    property var mode: null

    glyph: Theme.icons.warning
    iconSize: Theme.iconSizeSm
    iconColor: Theme.c.previewOptionsDecodeWarning.icon
    visible: glyph.mode !== undefined && glyph.mode.warn === true

    HoverHandler { id: decodeWarnHover }
    ThemedToolTip {
        text: glyph.mode ? glyph.mode.note : ""
        visible: glyph.visible && decodeWarnHover.hovered
    }
}
