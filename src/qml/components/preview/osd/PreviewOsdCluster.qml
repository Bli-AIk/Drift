import QtQuick
import Drift

// The top-right plate: zoom, guides, and preview options.
Rectangle {
    id: cluster

    property var viewport
    readonly property bool menuOpen: guideMenu.menuOpen
    readonly property bool menuBusy: optionsButton.menuBusy
    readonly property alias hovered: rightHover.hovered

    width: rightRow.implicitWidth + Theme.spacingXs * 2
    height: rightRow.implicitHeight + Theme.spacingXs * 2
    radius: Theme.radiusMd
    color: Theme.panelBackground
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    HoverHandler { id: rightHover }

    Row {
        id: rightRow
        anchors.centerIn: parent
        spacing: 0

        PreviewOsdZoomChip {
            viewport: cluster.viewport
        }

        PreviewOsdGuidesButton { }

        PreviewOsdGuideMenuButton {
            id: guideMenu
        }

        PreviewOsdOptionsButton {
            id: optionsButton
        }
    }
}
