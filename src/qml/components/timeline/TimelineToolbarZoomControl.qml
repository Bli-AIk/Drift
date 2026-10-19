import QtQuick
import Drift

// Zoom out, slider, numeric readout, zoom in, and fit.
Row {
    id: zoomControl

    property var host

    spacing: Theme.spacingSm

    TimelineToolbarToolButton {
        glyph: Theme.icons.zoomOut
        tooltip: qsTr("Zoom out")
        onClicked: zoomControl.host.panel.setZoom(zoomControl.host.panel.zoom / 1.5)
    }
    TimelineToolbarZoomSlider {
        panel: zoomControl.host.panel
    }
    TimelineToolbarZoomReadout {
        panel: zoomControl.host.panel
    }
    TimelineToolbarToolButton {
        glyph: Theme.icons.zoomIn
        tooltip: qsTr("Zoom in")
        onClicked: zoomControl.host.panel.setZoom(zoomControl.host.panel.zoom * 1.5)
    }
    TimelineToolbarToolButton {
        glyph: Theme.icons.zoomFit
        tooltip: qsTr("Fit timeline in view")
        onClicked: zoomControl.host.panel.fitZoom()
    }
}
