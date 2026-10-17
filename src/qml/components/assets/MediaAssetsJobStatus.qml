import QtQuick
import Drift
// A one-line background job under the bin navigation: label, thin progress, cancel.
Item {
    id: root

    property string label: ""
    property real progress: 0
    property string cancelTooltip: ""

    signal cancelRequested()

    height: visible ? Math.max(statusText.implicitHeight + Theme.spacingSm + statusBar.height,
                               cancelButton.height)
                    : 0

    Text {
        id: statusText
        anchors.left: parent.left
        anchors.right: cancelButton.left
        anchors.rightMargin: Theme.spacingMd
        anchors.top: parent.top
        text: root.label
        color: Theme.c.mediaAssetsJobStatus.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        elide: Text.ElideMiddle
    }
    ThemedProgressBar {
        id: statusBar
        anchors.left: parent.left
        anchors.right: cancelButton.left
        anchors.rightMargin: Theme.spacingMd
        anchors.top: statusText.bottom
        anchors.topMargin: Theme.spacingSm
        barHeight: Theme.spacingXs
        value: root.progress
    }
    IconButton {
        id: cancelButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        glyph: Theme.icons.x
        variant: "ghost"
        tooltip: root.cancelTooltip
        onClicked: root.cancelRequested()
    }
}
