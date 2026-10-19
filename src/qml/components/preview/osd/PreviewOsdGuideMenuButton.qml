import QtQuick
import Drift
IconButton {
    id: button

    readonly property alias menuOpen: guidesPopover.opened

    anchors.verticalCenter: parent.verticalCenter
    glyph: Theme.icons.chevronDown
    variant: "text"
    tooltip: qsTr("Guide sets")
    buttonSize: Theme.iconButtonSize * 0.6
    iconSize: Theme.iconSizeBase * 0.75
    active: guidesPopover.visible
    onClicked: guidesPopover.opened ? guidesPopover.close() : guidesPopover.open()

    GuidesPopover {
        id: guidesPopover
        x: parent.width - width
        y: parent.height + Theme.spacingMd
    }
}
