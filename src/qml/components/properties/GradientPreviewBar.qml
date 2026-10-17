import QtQuick
import Drift

Canvas {
    property var editor
    id: previewBar
    width: parent.width
    height: 28
    onPaint: {
        const ctx = getContext("2d")
        editor.paintBar(ctx, width, height, editor.shownStops)
    }
    onWidthChanged: requestPaint()
    Connections {
        target: editor
        function onShownStopsChanged() { previewBar.requestPaint() }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: Theme.c.gradientPreviewBar.radius
        border.width: Theme.c.gradientPreviewBar.borderWidth
        border.color: Theme.c.gradientPreviewBar.border
    }
}
