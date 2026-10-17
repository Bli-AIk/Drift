import QtQuick
import Drift

// Frame around the whole canvas when a drop would land as a new overlay.
Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.c.previewDropCanvasFrame.background.r, Theme.c.previewDropCanvasFrame.background.g, Theme.c.previewDropCanvasFrame.background.b, 0.08)
    border.width: Theme.c.previewDropCanvasFrame.borderWidth
    border.color: Theme.c.previewDropCanvasFrame.border
}
