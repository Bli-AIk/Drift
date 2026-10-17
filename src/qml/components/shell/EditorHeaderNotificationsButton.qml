import QtQuick
import Drift
import QtQuick.Window

// Every toast this session, plus an available update pinned on top. The update check
// is silent, so the dot here is its whole notification.
Item {
    id: bellButton
    implicitWidth: bellBtn.implicitWidth
    implicitHeight: bellBtn.implicitHeight
    width: implicitWidth
    height: implicitHeight
    anchors.verticalCenter: parent.verticalCenter

    readonly property bool updatePending: Updates.updateAvailable && Qt.platform.os !== "android"

    IconButton {
        id: bellBtn
        anchors.fill: parent
        glyph: Theme.icons.bell
        variant: "ghost"
        active: notificationsPopup.opened
        tooltip: bellButton.updatePending
                 ? qsTr("Notifications — Drift %1 is available").arg(Updates.latestVersion)
                 : qsTr("Notifications")
        onClicked: notificationsPopup.opened ? notificationsPopup.close()
                                             : notificationsPopup.open()
    }

    Rectangle {
        visible: Toasts.unreadCount > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingXs
        width: Math.max(Theme.spacingXl, unreadCount.implicitWidth + Theme.spacingSm)
        height: Theme.spacingXl
        radius: height / 2
        color: Theme.primary

        Text {
            id: unreadCount
            anchors.centerIn: parent
            text: Toasts.unreadCount > 99 ? "99+" : String(Toasts.unreadCount)
            color: Theme.primaryForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }

    Rectangle {
        visible: bellButton.updatePending && Toasts.unreadCount === 0
        width: 8
        height: 8
        radius: width / 2
        color: Theme.primary
        border.width: Theme.borderWidth
        border.color: Theme.panelBackground
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 3
    }

    NotificationsPopup {
        id: notificationsPopup
        x: parent.width - width
        y: parent.height + Theme.spacingMd
        onUpdateRequested: Window.window.openUpdateDialog()
    }

    Connections {
        target: Toasts
        function onHistoryRequested() {
            if (bellButton.visible)
                notificationsPopup.open()
        }
    }
}
