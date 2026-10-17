import QtQuick
import Drift

// Gap message drawn on the letterbox scrim. Fades rather than popping.
Text {
    id: caption

    required property bool show
    required property string message

    anchors.centerIn: parent
    visible: opacity > 0
    opacity: caption.show ? 1 : 0
    text: caption.message
    // Drawn on the letterbox scrim, not a panel surface, so it follows the on-media tokens in
    // both themes.
    color: Theme.guideMedium
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSm

    Behavior on opacity {
        NumberAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
    }
}
