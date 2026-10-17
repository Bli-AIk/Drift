import QtQuick
import QtQuick.Controls.Basic
import Drift

Rectangle {
    property Popup popup
    required property var modelData
    required property int index
    id: projectRow

    property string title
    property string subtitle
    property string tip
    property color statusColor: Theme.constructive
    property bool showCheck: false
    property bool removable: false
    property bool interactive: true
    property bool highlighted: false
    readonly property bool hovered: rowHover.hovered
    signal triggered()
    signal removeRequested()

    width: parent ? parent.width : 0
    height: subtitle.length > 0 ? 48 : 40
    radius: Theme.radiusSm
    color: (hovered && interactive) || highlighted ? Theme.accent : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    HoverHandler {
        id: rowHover
    }

    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingLg
        anchors.right: trailingRow.left
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: projectRow.statusColor
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            width: Math.max(0, leadingRow.width - 8 - Theme.spacingLg)
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: projectRow.title
                color: projectRow.interactive || projectRow.showCheck
                       ? Theme.foreground : Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: projectRow.showCheck ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: projectRow.subtitle.length > 0
                text: projectRow.subtitle
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                elide: Text.ElideLeft
            }
        }
    }

    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSm

        IconGlyph {
            id: checkIcon
            visible: projectRow.showCheck
            glyph: Theme.icons.check
            iconSize: Theme.iconSizeMd
            iconColor: Theme.mutedForeground
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: removeButton
            width: Theme.iconSizeMd + Theme.spacingSm
            height: Theme.iconSizeMd + Theme.spacingSm
            visible: projectRow.removable
            opacity: projectRow.hovered ? 1 : 0
            anchors.verticalCenter: parent.verticalCenter

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
            }

            IconGlyph {
                anchors.centerIn: parent
                glyph: Theme.icons.x
                iconSize: Theme.iconSizeMd
                iconColor: removeArea.containsMouse ? Theme.foreground : Theme.mutedForeground
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
                // Keep the row from treating this as an open click.
                onClicked: (mouse) => {
                    mouse.accepted = true
                    projectRow.removeRequested()
                }
            }
        }
    }

    ThemedToolTip {
        text: projectRow.tip
        visible: projectRow.tip.length > 0 && rowHover.hovered && !removeArea.containsMouse
    }

    MouseArea {
        id: rowArea
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: trailingRow.left
        hoverEnabled: true
        cursorShape: projectRow.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (!projectRow.interactive)
                return
            popup.close()
            projectRow.triggered()
        }
    }
}
