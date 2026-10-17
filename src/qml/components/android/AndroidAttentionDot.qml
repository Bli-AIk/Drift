import QtQuick
import Drift

// 8dp status pip: unsaved work, an available update, an add-on that needs attention.
Rectangle {
    property color dotColor: Theme.destructive

    width: 8
    height: 8
    radius: 4
    color: dotColor
}
