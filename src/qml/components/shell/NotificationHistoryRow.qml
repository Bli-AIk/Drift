import QtQuick
import Drift

Item {
    property NotificationList host
    id: row

    required property int toastId
    required property string severity
    required property string message
    required property int repeats
    required property string actionText
    required property string time
    required property bool unread

    width: ListView.view.width
    height: Math.max(host.rowHeight, body.implicitHeight + Theme.spacingLg * 2)

    IconGlyph {
        id: rowIcon
        anchors.left: parent.left
        anchors.leftMargin: host.horizontalPadding
        anchors.top: parent.top
        anchors.topMargin: Theme.spacingLg
        glyph: host._glyph(row.severity)
        iconSize: Theme.iconSizeBase
        iconColor: {
            switch (row.severity) {
            case "error": return Theme.c.notificationHistoryRow.accentError
            case "warning": return Theme.c.notificationHistoryRow.accentWarning
            case "success": return Theme.c.notificationHistoryRow.accentSuccess
            default: return Theme.c.notificationHistoryRow.accent
            }
        }
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
            color: Theme.c.notificationHistoryRow.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: row.unread ? Font.Medium : Font.Normal
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: row.time
            color: Theme.c.notificationHistoryRow.foregroundMuted
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
            host.actionTaken()
        }
    }

    Rectangle {
        id: unreadDot
        anchors.right: parent.right
        anchors.rightMargin: host.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: Theme.c.notificationHistoryRow.indicatorRadius
        color: Theme.c.notificationHistoryRow.indicator
        opacity: row.unread ? 1 : 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: host.horizontalPadding
        anchors.right: parent.right
        anchors.rightMargin: host.horizontalPadding
        anchors.bottom: parent.bottom
        height: Theme.c.notificationHistoryRow.borderWidth
        color: Theme.c.notificationHistoryRow.divider
    }
}
