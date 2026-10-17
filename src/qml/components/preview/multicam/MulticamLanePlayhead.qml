import QtQuick
import Drift

Rectangle {
    id: head

    required property real fraction

    width: 2
    height: parent.height
    x: Math.round(parent.width * head.fraction) - 1
    color: Theme.primary
}
