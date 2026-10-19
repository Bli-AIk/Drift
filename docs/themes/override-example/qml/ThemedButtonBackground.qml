import QtQuick

// Replaces ThemedButton's background when this theme is trusted.
// `control` is the button (down, hovered, pressed, variant, and the rest).
Rectangle {
    property var control

    color: control && control.down ? "#ffffff" : "#ff00aa"
    radius: 6
    border.width: 1
    border.color: "#ff00aa"
}
