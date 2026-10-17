import QtQuick
import Drift

// Frame around the whole canvas when a drop would land as a new overlay.
Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
    border.width: 2
    border.color: Theme.primary
}
