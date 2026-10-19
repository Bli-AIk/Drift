import QtQuick
import Drift

// The top-right plate: zoom, guides, and preview options.
Item {
    id: cluster

    property var viewport
    readonly property bool menuOpen: guideMenu.menuOpen
    readonly property bool menuBusy: optionsButton.menuBusy
    readonly property alias hovered: rightHover.hovered

    width: rightRow.implicitWidth + Theme.spacingXs * 2
    height: rightRow.implicitHeight + Theme.spacingXs * 2

    ThemeSlot {
        anchors.fill: parent
        slot: "PreviewOsdClusterBackground"
        control: cluster
        fallback: Component {
            Rectangle {
                anchors.fill: parent
                radius: Theme.c.previewOsdCluster.radius
                color: Theme.c.previewOsdCluster.background
                border.width: Theme.c.previewOsdCluster.borderWidth
                border.color: Theme.c.previewOsdCluster.border
            }
        }
    }

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
