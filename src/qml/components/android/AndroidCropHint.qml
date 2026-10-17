import QtQuick
import Drift

// First-run hint. The crop frame is the only thing on screen that can be
// dragged, and nothing else says so; it retires once the user has dragged.
Rectangle {
    id: hint

    property bool retired: false

    width: hintLabel.width + Theme.spacing2xl
    height: hintLabel.height + Theme.spacingLg
    radius: Theme.radiusSm
    // Sits on the preview scrim, not a panel surface, so it uses the on-media
    // tokens — panelForeground would go dark-on-dark in light mode.
    color: Theme.scrimStrong
    border.width: Theme.borderWidth
    border.color: Theme.guideWeak

    opacity: hint.retired ? 0 : 1
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationSlow; easing.type: Theme.easing }
    }

    Text {
        id: hintLabel
        anchors.centerIn: parent
        text: qsTr("Drag the edges to reframe · pinch to zoom")
        color: Theme.onMedia
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
