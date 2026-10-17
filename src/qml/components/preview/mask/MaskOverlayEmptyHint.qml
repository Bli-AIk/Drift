import QtQuick
import Drift

// Nothing to manipulate: no clip under the playhead, or the clip has no mask layers.
Rectangle {
    id: hint

    required property bool hasFrame

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.spacingLg
    width: hintText.width + Theme.spacingLg * 2
    height: hintText.height + Theme.spacingMd * 2
    radius: Theme.c.maskOverlayEmptyHint.radius
    color: Theme.c.maskOverlayEmptyHint.background
    opacity: Theme.c.maskOverlayEmptyHint.opacity

    Text {
        id: hintText
        anchors.centerIn: parent
        text: hint.hasFrame ? qsTr("Drag a mask from the Masks tab onto a clip to edit it here")
                            : qsTr("Select a clip at the playhead to edit its masks")
        color: Theme.c.maskOverlayEmptyHint.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
