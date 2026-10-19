import QtQuick
import Drift
IconButton {
    id: button

    readonly property alias menuBusy: optionsMenu.busy

    glyph: Theme.icons.ellipsis
    variant: "text"
    tooltip: qsTr("Preview options")
    active: optionsMenu.visible
    onClicked: optionsMenu.opened ? optionsMenu.close() : optionsMenu.open()

    PreviewOptionsMenu {
        id: optionsMenu
        x: parent.width - width
        y: parent.height + Theme.spacingMd
    }
}
