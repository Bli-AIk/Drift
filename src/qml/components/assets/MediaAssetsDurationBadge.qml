import QtQuick
import Drift

// Duration chip painted on the bottom-right of a media thumbnail.
Rectangle {
    id: root

    property string label: ""

    visible: label.length > 0
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Theme.spacingSm
    color: Theme.scrimStrong
    radius: Theme.radiusXs
    width: durationLabel.implicitWidth + Theme.spacingLg
    height: durationLabel.implicitHeight + Theme.spacingSm

    Text {
        id: durationLabel
        anchors.centerIn: parent
        text: root.label
        color: Theme.onMedia
        font.pixelSize: Theme.fontSizeXs
        font.family: Theme.fontFamily
    }
}
