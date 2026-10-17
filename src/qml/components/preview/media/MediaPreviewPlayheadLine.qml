import QtQuick
import Drift

Rectangle {
    id: line

    required property real playX

    x: line.playX - 1
    width: 2
    height: parent.height
    color: Theme.primary
    z: 3
}
