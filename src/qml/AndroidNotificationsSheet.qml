import QtQuick
import Drift
import "components"

// The top bar bell's list on the phone. Marked read on close, like the desktop popup.
AndroidBottomSheet {
    id: root

    title: qsTr("Notifications")

    onClosed: Toasts.markAllRead()

    NotificationList {
        anchors.fill: parent
        horizontalPadding: Theme.androidPagePadding
        rowHeight: Theme.androidAddRowHeight
        showTitle: false
        onActionTaken: root.close()
    }
}
