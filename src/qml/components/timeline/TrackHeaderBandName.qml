import QtQuick
import Drift

// Track name along the top of a header tall enough to hold it.
Text {
    property string label: ""
    anchors.left: parent.left
    anchors.leftMargin: Theme.spacing3xl + Theme.spacingSm
    anchors.right: parent.right
    anchors.rightMargin: Theme.spacingLg
    anchors.top: parent.top
    anchors.topMargin: Theme.spacingMd
    text: label
    color: Theme.c.trackHeaderBandName.foregroundMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeTiny
    elide: Text.ElideRight
}
