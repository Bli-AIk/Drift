import QtQuick
import QtQuick.Layouts
import Drift
IconButton {
    id: button

    required property bool fullscreen
    signal fullscreenRequested()

    Layout.alignment: Qt.AlignVCenter
    glyph: button.fullscreen ? Theme.icons.minimize : Theme.icons.maximize
    variant: "text"
    tooltip: button.fullscreen ? qsTr("Exit fullscreen preview (Esc)") : qsTr("Fullscreen preview")
    active: button.fullscreen
    // The window and the surrounding panels belong to Main, so the toggle is requested
    // rather than performed here.
    onClicked: button.fullscreenRequested()
}
