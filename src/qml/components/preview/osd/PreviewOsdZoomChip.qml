import QtQuick
import Drift
// Shown only once the view has moved, and the way back to 100%.
Item {
    id: chip

    property var viewport

    visible: !!chip.viewport && chip.viewport.viewMoved
    width: visible ? zoomText.implicitWidth + Theme.spacingMd * 2 : 0
    height: Theme.iconButtonSize

    Text {
        id: zoomText
        anchors.centerIn: parent
        text: chip.viewport ? Math.round(chip.viewport.userZoom * 100) + "%" : ""
        color: zoomMouse.containsMouse ? Theme.c.previewOsdZoomChip.foregroundHover : Theme.c.previewOsdZoomChip.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    MouseArea {
        id: zoomMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (chip.viewport) chip.viewport.resetView()
    }

    ThemedToolTip {
        text: Theme.platformShortcutText(
                  qsTr("Preview zoom — Ctrl+scroll over the preview to zoom, "
                     + "middle-drag to pan. Click to reset to 100%."))
        visible: zoomMouse.containsMouse
    }
}
