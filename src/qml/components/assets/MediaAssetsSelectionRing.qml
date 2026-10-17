import QtQuick
import Drift

// A dedicated overlay for the selection ring, painted above the
// thumbnail image and busy scrim (both earlier siblings) so it
// is never covered by them. Square corners on purpose — a
// rounded ring here reads chunkier than the thumbnail's own
// radius at this border width.
Rectangle {
    id: root

    property bool selected: false

    z: 2
    anchors.fill: parent
    radius: 0
    color: "transparent"
    border.width: selected ? Theme.clipSelectionRingWidth : 0
    border.color: Theme.primary

    Behavior on border.width {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }
}
