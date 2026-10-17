import QtQuick
import Drift

// Outline of the clip an effect or mask would land on. The parent places it.
Rectangle {
    color: Qt.rgba(Theme.c.previewDropClipFrame.background.r, Theme.c.previewDropClipFrame.background.g, Theme.c.previewDropClipFrame.background.b, 0.12)
    border.width: Theme.c.previewDropClipFrame.borderWidth
    border.color: Theme.c.previewDropClipFrame.border
}
