import QtQuick
import Drift

Rectangle {
    signal openRequested(string path)
    id: projectRow

    required property var modelData
    readonly property bool exists: modelData.exists !== false
    readonly property bool hovered: rowHover.hovered

    width: ListView.view ? ListView.view.width : 0
    height: 56
    radius: Theme.c.startScreenProjectRow.radius
    color: hovered && exists ? Theme.c.startScreenProjectRow.backgroundHover
                             : Theme.c.startScreenProjectRow.background
    border.width: Theme.c.startScreenProjectRow.borderWidth
    border.color: Theme.c.startScreenProjectRow.border
    opacity: exists ? 1 : 0.6

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    HoverHandler {
        id: rowHover
    }

    Row {
        anchors.left: parent.left
        anchors.right: removeButton.left
        anchors.leftMargin: Theme.spacingXl
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        Rectangle {
            width: 8
            height: 8
            radius: Theme.c.startScreenProjectRow.statusRadius
            anchors.verticalCenter: parent.verticalCenter
            color: projectRow.exists ? Theme.c.startScreenProjectRow.statusExists
                                     : Theme.c.startScreenProjectRow.statusMissing
        }

        Column {
            width: parent.width - 8 - Theme.spacingLg
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: projectRow.modelData.name + (projectRow.exists ? "" : qsTr(" (missing)"))
                color: Theme.c.startScreenProjectRow.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: projectRow.modelData.path
                color: Theme.c.startScreenProjectRow.foregroundMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                elide: Text.ElideLeft
            }
        }
    }

    ThemedToolTip {
        text: projectRow.exists
              ? projectRow.modelData.path
              : qsTr("This file has been moved or deleted:\n%1").arg(projectRow.modelData.path)
        visible: projectRow.hovered && !removeArea.containsMouse
    }

    Item {
        id: removeButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.iconSizeMd + Theme.spacingSm
        height: Theme.iconSizeMd + Theme.spacingSm
        opacity: projectRow.hovered ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
        }

        IconGlyph {
            anchors.centerIn: parent
            glyph: Theme.icons.x
            iconSize: Theme.iconSizeMd
            iconColor: removeArea.containsMouse ? Theme.c.startScreenProjectRow.iconHover
                                                : Theme.c.startScreenProjectRow.icon
        }

        ThemedToolTip {
            text: qsTr("Remove from recents")
            visible: removeArea.containsMouse
        }

        MouseArea {
            id: removeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                mouse.accepted = true
                EditorState.projectFile.removeRecentProject(projectRow.modelData.path)
            }
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: removeButton.left
        hoverEnabled: true
        cursorShape: projectRow.exists ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!projectRow.exists)
                return
            projectRow.openRequested(projectRow.modelData.path)
        }
    }
}
