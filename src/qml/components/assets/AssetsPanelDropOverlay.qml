import QtQuick
import Drift
// Drag feedback. Dropping files onto the panel used to give no visual
// confirmation that it was even a valid target.
Rectangle {
    id: root

    property bool active: false

    anchors.fill: parent
    z: 50
    radius: Theme.c.assetsPanelDropOverlay.radius
    color: Qt.rgba(Theme.c.assetsPanelDropOverlay.accent.r, Theme.c.assetsPanelDropOverlay.accent.g, Theme.c.assetsPanelDropOverlay.accent.b, 0.08)
    border.width: Theme.c.assetsPanelDropOverlay.borderWidth
    border.color: Theme.c.assetsPanelDropOverlay.accent
    visible: opacity > 0
    opacity: active ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    EmptyState {
        anchors.centerIn: parent
        glyph: Theme.icons.upload
        title: qsTr("Drop to import")
        hint: qsTr("Video, audio and image files")
    }
}
