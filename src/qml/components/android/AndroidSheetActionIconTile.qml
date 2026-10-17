import QtQuick
import Drift

// The 40dp icon square at the leading edge of a sheet action row.
Rectangle {
    id: tile

    property string glyph: ""
    property color tint: Theme.c.androidSheetActionIconTile.foreground

    width: 40
    height: 40
    radius: Theme.c.androidSheetActionIconTile.radius
    color: Theme.c.androidSheetActionIconTile.background

    IconGlyph {
        anchors.centerIn: parent
        glyph: tile.glyph
        iconSize: Theme.iconSizeLg
        iconColor: tile.tint
    }
}
