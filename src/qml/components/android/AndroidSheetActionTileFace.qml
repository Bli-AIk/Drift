import QtQuick
import Drift

// The icon square of a bottom-sheet action grid cell.
Rectangle {
    id: face

    property string glyph: ""
    property bool toggled: false
    property bool pressed: false

    width: Theme.androidMinTouchTarget
    height: Theme.androidMinTouchTarget
    radius: Theme.c.androidSheetActionTileFace.radius
    color: face.toggled
           ? Qt.rgba(Theme.c.androidSheetActionTileFace.backgroundToggled.r,
                     Theme.c.androidSheetActionTileFace.backgroundToggled.g,
                     Theme.c.androidSheetActionTileFace.backgroundToggled.b, 0.22)
           : (face.pressed ? Theme.c.androidSheetActionTileFace.backgroundPressed
                           : Theme.c.androidSheetActionTileFace.background)
    border.width: face.toggled ? Theme.c.androidSheetActionTileFace.borderWidth : 0
    border.color: Theme.c.androidSheetActionTileFace.border

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    IconGlyph {
        anchors.centerIn: parent
        glyph: face.glyph
        iconSize: Theme.iconSizeLg
        iconColor: face.toggled ? Theme.c.androidSheetActionTileFace.iconToggled : Theme.c.androidSheetActionTileFace.icon
    }
}
