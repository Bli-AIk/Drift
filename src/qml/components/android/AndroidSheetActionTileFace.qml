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
    radius: Theme.radiusMd
    color: face.toggled
           ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
           : (face.pressed ? Theme.popoverHover : Theme.panelAccent)
    border.width: face.toggled ? Theme.borderWidth : 0
    border.color: Theme.primary

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    IconGlyph {
        anchors.centerIn: parent
        glyph: face.glyph
        iconSize: Theme.iconSizeLg
        iconColor: face.toggled ? Theme.accentOnPanel : Theme.panelForeground
    }
}
