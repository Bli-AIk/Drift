import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift
import "components"

// Slim CapCut-style editor top bar.
Item {
    id: root

    signal backRequested()
    signal exportRequested()
    signal exportProgressRequested()
    // The project title is the affordance: a wide, self-labelling target in the middle of
    // the bar rather than an unlabelled glyph in the corner.
    signal projectMenuRequested()
    signal downloadsRequested()
    signal notificationsRequested()

    readonly property int downloadCount: {
        void Market.downloadsRevision
        return Market.downloads.length
    }
    readonly property int activeDownloadCount: {
        void Market.downloadsRevision
        return Market.activeDownloadCount
    }

    // Status bar / camera cutout. Without it the Back, Undo and Export buttons sat
    // underneath the system bar on every edge-to-edge device.
    readonly property real topInset: SafeArea.margins.top
    readonly property real leftInset: SafeArea.margins.left
    readonly property real rightInset: SafeArea.margins.right

    height: Theme.androidTopBarHeight + topInset
    width: parent ? parent.width : 0

    Rectangle {
        anchors.fill: parent
        color: Theme.panelBackground
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.panelBorder
    }

    Item {
        id: barBody
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.leftInset
        anchors.rightMargin: root.rightInset
        height: Theme.androidTopBarHeight

        IconButton {
            id: backBtn
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeLg
            glyph: Theme.icons.chevronLeft
            variant: "text"
            tooltip: qsTr("Back")
            onClicked: root.backRequested()
        }

        AbstractButton {
            id: titleBtn
            anchors.left: backBtn.right
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.androidIconButtonSize
            hoverEnabled: true

            Accessible.role: Accessible.Button
            Accessible.name: titleText.text
            Accessible.description: qsTr("Project actions")

            scale: titleBtn.down ? Theme.pressScale : 1.0

            Behavior on scale {
                NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
            }

            background: Rectangle {
                radius: Theme.radiusSm
                color: titleBtn.down ? Theme.panelAccent : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                }
            }

            contentItem: Row {
                spacing: Theme.spacingMd
                leftPadding: Theme.spacingMd
                rightPadding: Theme.spacingMd

                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    // Clamped against what the right-hand cluster actually leaves, not a
                    // fixed 140: the export pill is wider than the icon it replaced.
                    width: Math.min(implicitWidth,
                                    Math.max(0, barBody.width - actionsRow.width - backBtn.width
                                                - Theme.iconSizeMd - Theme.spacing3xl))
                    text: EditorState.projectFile.projectName.length > 0
                          ? EditorState.projectFile.projectName
                          : qsTr("Untitled")
                    color: Theme.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: EditorState.projectFile.hasUnsavedChanges ? Theme.destructive : Theme.constructive
                }

                IconGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Theme.icons.chevronDown
                    iconSize: Theme.iconSizeMd
                    iconColor: Theme.mutedForeground

                    // The update row lives in the project sheet's App section.
                    Rectangle {
                        visible: Updates.updateAvailable
                        anchors.right: parent.right
                        anchors.top: parent.top
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.destructive
                    }
                }
            }

            onClicked: {
                Haptics.press()
                root.projectMenuRequested()
            }
        }

        Row {
            id: actionsRow
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXs

            IconButton {
                buttonSize: Theme.androidIconButtonSize
                iconSize: Theme.iconSizeLg
                glyph: Theme.icons.bell
                variant: "text"
                tooltip: qsTr("Notifications")
                onClicked: root.notificationsRequested()

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingXs
                    visible: Toasts.unreadCount > 0
                    width: Math.max(Theme.spacingXl, unreadText.implicitWidth + Theme.spacingSm)
                    height: Theme.spacingXl
                    radius: height / 2
                    color: Theme.primary

                    Text {
                        id: unreadText
                        anchors.centerIn: parent
                        text: Toasts.unreadCount > 99 ? "99+" : String(Toasts.unreadCount)
                        color: Theme.primaryForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                    }
                }
            }

            // The way into the downloads sheet, and the only one: the sheet never raises itself,
            // because the per-tile ring is what lets browsing carry on while things download.
            IconButton {
                visible: root.downloadCount > 0
                buttonSize: Theme.androidIconButtonSize
                iconSize: Theme.iconSizeLg
                glyph: Theme.icons.download
                variant: "text"
                tooltip: qsTr("Downloads")
                onClicked: root.downloadsRequested()

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingXs
                    visible: root.activeDownloadCount > 0
                    width: Theme.spacingXl
                    height: width
                    radius: width / 2
                    color: Theme.primary

                    Text {
                        anchors.centerIn: parent
                        text: String(root.activeDownloadCount)
                        color: Theme.primaryForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                    }
                }
            }

            IconButton {
                buttonSize: Theme.androidIconButtonSize
                iconSize: Theme.iconSizeLg
                glyph: Theme.icons.puzzle
                variant: "text"
                tooltip: qsTr("Extras")
                onClicked: Window.window.openExtras()

                Rectangle {
                    visible: Window.window.addonAttentionNeeded
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingSm
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.destructive
                }
            }

            // Undo/Redo stay icon-only — the one documented exception, and long-pressable
            // for a label now that IconButton shows its tooltip on touch.
            IconButton {
                buttonSize: Theme.androidIconButtonSize
                iconSize: Theme.iconSizeLg
                glyph: Theme.icons.undo
                variant: "text"
                tooltip: qsTr("Undo")
                enabled: EditorState.undoAvailable
                onClicked: EditorState.undo()
            }

            IconButton {
                buttonSize: Theme.androidIconButtonSize
                iconSize: Theme.iconSizeLg
                glyph: Theme.icons.redo
                variant: "text"
                tooltip: qsTr("Redo")
                enabled: EditorState.redoAvailable
                onClicked: EditorState.redo()
            }

            // Doubles as the way back into a render whose progress sheet was dismissed:
            // without it a running export is unreachable and uncancellable, there being no
            // second window on a phone to leave it open in. The ring is drawn around the
            // glyph rather than replacing it, so the pill keeps its width and its label
            // while the render runs.
            ThemedButton {
                id: exportPill
                anchors.verticalCenter: parent.verticalCenter
                variant: "primary"
                glyph: Theme.icons.upload
                text: qsTr("Export")
                tooltip: EditorState.exportInProgress ? qsTr("Show export progress")
                                                      : qsTr("Export")
                onClicked: EditorState.exportInProgress ? root.exportProgressRequested()
                                                        : root.exportRequested()

                CircularProgress {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingXl + Theme.iconSizeMd / 2 - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    visible: EditorState.exportInProgress
                    size: Theme.iconSizeXl
                    strokeWidth: 2
                    value: EditorState.exportProgress
                }
            }
        }
    }
}
