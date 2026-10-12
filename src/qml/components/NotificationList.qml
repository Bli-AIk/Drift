import QtQuick
import QtQuick.Controls.Basic
import Drift

// The bell's contents, shared by the desktop popup and the phone sheet: an available
// app update pinned on top, then every toast this session, newest first.
Item {
    id: root

    property real horizontalPadding: Theme.spacingLg
    property real rowHeight: Theme.controlHeight + Theme.spacingXl
    // The phone sheet titles itself, so only its Clear button is wanted.
    property bool showTitle: true

    signal updateRequested()
    // An entry's button ran; the host closes.
    signal actionTaken()

    // Phone updates come from the store, so the row only exists on desktop.
    readonly property bool showUpdate: Updates.updateAvailable && Qt.platform.os !== "android"

    function _accent(severity) {
        switch (severity) {
        case "error": return Theme.destructive
        case "warning": return Theme.warning
        case "success": return Theme.constructive
        default: return Theme.primary
        }
    }

    function _glyph(severity) {
        switch (severity) {
        case "error": return Theme.icons.error
        case "warning": return Theme.icons.warning
        case "success": return Theme.icons.success
        default: return Theme.icons.info
        }
    }

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.showTitle || Toasts.history.count > 0 ? Theme.controlHeight + Theme.spacingMd : 0

        Text {
            visible: root.showTitle
            anchors.left: parent.left
            anchors.leftMargin: root.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Notifications")
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
        }

        ThemedButton {
            anchors.right: parent.right
            anchors.rightMargin: root.horizontalPadding - Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            visible: Toasts.history.count > 0
            variant: "ghost"
            text: qsTr("Clear")
            onClicked: Toasts.clearHistory()
        }
    }

    Rectangle {
        id: updateRow
        visible: root.showUpdate
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: visible ? root.rowHeight + Theme.spacingSm : 0
        color: updateArea.containsMouse ? Qt.darker(Theme.accent, 1.08) : Theme.accent

        // The whole row opens the dialog, not just its button.
        MouseArea {
            id: updateArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.updateRequested()
        }

        IconGlyph {
            id: updateIcon
            anchors.left: parent.left
            anchors.leftMargin: root.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.download
            iconSize: Theme.iconSizeBase
            iconColor: Theme.primary
        }

        Text {
            anchors.left: updateIcon.right
            anchors.leftMargin: Theme.spacingMd
            anchors.right: updateButton.left
            anchors.rightMargin: Theme.spacingMd
            anchors.verticalCenter: parent.verticalCenter
            text: Updates.readyToInstall
                  ? qsTr("Drift %1 is ready to install").arg(Updates.latestVersion)
                  : qsTr("Drift %1 is available").arg(Updates.latestVersion)
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        ThemedButton {
            id: updateButton
            anchors.right: parent.right
            anchors.rightMargin: root.horizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            variant: "primary"
            text: qsTr("Update")
            onClicked: root.updateRequested()
        }
    }

    ThemedLabel {
        anchors.top: updateRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        visible: Toasts.history.count === 0
        text: qsTr("No notifications yet.")
    }

    ListView {
        id: list
        anchors.top: updateRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        model: Toasts.history
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AppScrollBar { }

        delegate: Item {
            id: row

            required property int toastId
            required property string severity
            required property string message
            required property int repeats
            required property string actionText
            required property string time
            required property bool unread

            width: list.width
            height: Math.max(root.rowHeight, body.implicitHeight + Theme.spacingLg * 2)

            IconGlyph {
                id: rowIcon
                anchors.left: parent.left
                anchors.leftMargin: root.horizontalPadding
                anchors.top: parent.top
                anchors.topMargin: Theme.spacingLg
                glyph: root._glyph(row.severity)
                iconSize: Theme.iconSizeBase
                iconColor: root._accent(row.severity)
            }

            Column {
                id: body
                anchors.left: rowIcon.right
                anchors.leftMargin: Theme.spacingMd
                anchors.right: rowAction.visible ? rowAction.left : unreadDot.left
                anchors.rightMargin: Theme.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: row.repeats > 1
                          ? qsTr("%1  (×%2)").arg(row.message).arg(row.repeats)
                          : row.message
                    color: Theme.panelForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: row.unread ? Font.Medium : Font.Normal
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: row.time
                    color: Theme.mutedForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                }
            }

            ThemedButton {
                id: rowAction
                anchors.right: unreadDot.left
                anchors.rightMargin: Theme.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                visible: row.actionText.length > 0
                text: row.actionText
                variant: "secondary"
                onClicked: {
                    Toasts.trigger(row.toastId)
                    root.actionTaken()
                }
            }

            Rectangle {
                id: unreadDot
                anchors.right: parent.right
                anchors.rightMargin: root.horizontalPadding
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: Theme.primary
                opacity: row.unread ? 1 : 0
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: root.horizontalPadding
                anchors.right: parent.right
                anchors.rightMargin: root.horizontalPadding
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.panelBorder
            }
        }
    }
}
