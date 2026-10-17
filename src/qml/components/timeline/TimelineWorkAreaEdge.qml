import QtQuick
import Drift

// In or out marker of the work area.
Rectangle {
    property bool shown: false
    property real edgeX: 0

    visible: shown
    x: edgeX
    width: 2
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    color: Theme.primary
    opacity: 0.85
}
