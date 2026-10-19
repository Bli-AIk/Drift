import QtQuick
import Drift

// Logarithmic timeline zoom slider.
ThemedSlider {
    id: zoomSlider

    property var panel

    label: qsTr("Timeline zoom")
    width: 112
    anchors.verticalCenter: parent.verticalCenter
    // Logarithmic mapping so the wide zoom range stays controllable.
    from: 0
    to: 1
    value: Math.log(panel.zoom / panel.minZoom) / Math.log(panel.maxZoom / panel.minZoom)
    onMoved: panel.setZoom(panel.minZoom * Math.pow(panel.maxZoom / panel.minZoom, value))
    // There was no zoom readout anywhere, so the current level
    // was simply unknowable.
    valueFormatter: function () {
        return qsTr("Zoom %1×").arg(panel.zoom.toFixed(2))
    }
}
