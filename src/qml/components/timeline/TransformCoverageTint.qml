import QtQuick
import Drift

// Tint over one track a selected transform clip moves.
Rectangle {
    property TransformCoverageOverlay overlay
    required property var modelData
    visible: overlay.draggingTrack !== modelData
    x: overlay.layerClip ? overlay.layerClip.start * overlay.pxPerSecond : 0
    width: overlay.layerClip ? overlay.layerClip.duration * overlay.pxPerSecond : 0
    y: overlay.rowTop ? overlay.rowTop(modelData) : 0
    height: overlay.rowHeight ? overlay.rowHeight(modelData) : 0
    color: Qt.rgba(Theme.clipTransform.r, Theme.clipTransform.g, Theme.clipTransform.b, 0.14)
    border.width: 1
    border.color: Qt.rgba(Theme.clipTransform.r, Theme.clipTransform.g, Theme.clipTransform.b, 0.45)
    radius: Theme.radiusSm
}
