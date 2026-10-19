import QtQuick
import QtQuick.Controls.Basic
import Drift

// The header bell's dropdown. Everything is marked read on close rather than open, so
// the unread dots still say what is new while the list is up.
Popup {
    id: root

    signal updateRequested()

    width: 380
    height: Math.min(480, Math.max(160, list.implicitListHeight))
    padding: 0
    modal: true
    dim: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onClosed: Toasts.markAllRead()

    background: Rectangle {
        color: Theme.c.notificationsPopup.background
        border.width: Theme.c.notificationsPopup.borderWidth
        border.color: Theme.c.notificationsPopup.border
        radius: Theme.c.notificationsPopup.radius
    }

    // Opacity plus scale, matching ThemedContextMenu.
    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.durationBase
                easing.type: Theme.easing
            }
            NumberAnimation {
                property: "scale"
                from: 0.96
                to: 1.0
                duration: Theme.durationBase
                easing.type: Theme.easing
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Theme.durationFast
                easing.type: Theme.easing
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.96
                duration: Theme.durationFast
                easing.type: Theme.easing
            }
        }
    }

    contentItem: NotificationList {
        id: list

        // Rough fit so a short list does not open as a tall empty box.
        readonly property real implicitListHeight: Theme.controlHeight + Theme.spacingMd
                                                   + (showUpdate ? rowHeight + Theme.spacingSm : 0)
                                                   + Math.max(1, Toasts.history.count) * (rowHeight + Theme.spacingMd)

        onUpdateRequested: {
            root.close()
            root.updateRequested()
        }
        onActionTaken: root.close()
    }
}
