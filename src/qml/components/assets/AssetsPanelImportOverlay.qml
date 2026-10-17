import QtQuick
import Drift
// Import progress. Probing and thumbnailing a large selection blocks for a
// while; the panel used to simply appear frozen.
Rectangle {
    id: root

    property bool active: false

    anchors.fill: parent
    z: 60
    color: Theme.panelBackground
    opacity: active ? 0.92 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    EmptyState {
        anchors.centerIn: parent
        glyph: Theme.icons.spinner
        glyphSpinning: root.active
        title: qsTr("Importing…")
        hint: qsTr("Reading media and generating thumbnails.")
    }
}
