import QtQuick
import Drift

// Body of the ghost lane a drop would insert.
Rectangle {
    anchors.fill: parent
    radius: Theme.radiusSm
    color: Qt.rgba(Theme.panelBackground.r, Theme.panelBackground.g,
                   Theme.panelBackground.b, 0.92)
    border.width: Theme.borderWidth
    border.color: Theme.primary
}
