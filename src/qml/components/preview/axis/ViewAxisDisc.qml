import QtQuick

// Faint disc behind the axis ends. It fills in while the pointer is over the widget.
Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

    HoverHandler { id: hover }
}
