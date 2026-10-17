import QtQuick
import Drift
// Drag feedback. Dropping files onto the panel used to give no visual
// confirmation that it was even a valid target.
Rectangle {
    id: root

    property bool active: false

    anchors.fill: parent
    z: 50
    radius: Theme.radiusMd
    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
    border.width: Theme.borderWidthFocus
    border.color: Theme.primary
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
