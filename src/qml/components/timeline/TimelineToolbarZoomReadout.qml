import QtQuick
import Drift

// Numeric zoom level, and a click target to return to 1×.
Text {
    id: readout

    property var panel

    anchors.verticalCenter: parent.verticalCenter
    width: 44
    text: panel.zoom.toFixed(2) + "×"
    color: Theme.mutedForeground
    font.family: Theme.monoFontFamily
    font.pixelSize: Theme.fontSizeTick
    horizontalAlignment: Text.AlignHCenter

    ThemedToolTip {
        text: qsTr("Zoom level — click to reset to 1×. Ctrl+wheel over the timeline also zooms.")
        visible: zoomLabelMouse.containsMouse
    }

    MouseArea {
        id: zoomLabelMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: readout.panel.setZoom(1.0)
    }
}
