import QtQuick
import Drift

Rectangle {
    required property var dialog
    id: row

    required property var modelData

    readonly property var transfer: dialog.transfers[modelData.id]
    readonly property bool active: modelData.state === "downloading"
                                   || modelData.state === "installing"

    width: ListView.view.width
    height: body.implicitHeight + Theme.spacing3xl
    radius: Theme.c.addonManagerRow.radius
    // Rows had no hover state at all; only the highlighted row
    // differed from the rest.
    color: rowHover.hovered ? Theme.c.addonManagerRow.backgroundHover
                            : Theme.c.addonManagerRow.background
    border.width: Theme.c.addonManagerRow.borderWidth
    border.color: modelData.id === dialog.highlightId ? Theme.c.addonManagerRow.borderHighlight
                                                      : Theme.c.addonManagerRow.border

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    HoverHandler { id: rowHover }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: actions.left
        anchors.leftMargin: Theme.spacing2xl - Theme.spacingXs
        anchors.rightMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSm

        Row {
            // Bounded so a long addon name elides instead of pushing
            // the version label out of the row.
            width: body.width
            spacing: Theme.spacingLg

            ThemedLabel {
                id: nameLabel
                width: Math.min(implicitWidth,
                                body.width - versionLabel.width
                                - (infoButton.visible ? infoButton.width + parent.spacing : 0)
                                - parent.spacing)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                tone: "default"
                size: "base"
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            IconButton {
                id: infoButton
                anchors.verticalCenter: parent.verticalCenter
                visible: !!(row.modelData.details && row.modelData.details.length > 0)
                width: visible ? buttonSize : 0
                height: visible ? buttonSize : 0
                buttonSize: 22
                iconSize: Theme.iconSizeSm
                glyph: Theme.icons.info
                tooltip: qsTr("Technical details")
                onClicked: {
                    dialog.detailsName = row.modelData.name
                    dialog.detailsBody = row.modelData.details
                    var meta = []
                    if (row.modelData.id)
                        meta.push(row.modelData.id)
                    if (row.modelData.author)
                        meta.push(row.modelData.author)
                    if (row.modelData.license)
                        meta.push(row.modelData.license)
                    if (row.modelData.platform)
                        meta.push(row.modelData.platform)
                    dialog.detailsMeta = meta.join(" · ")
                    detailsDialog.open()
                }
            }

            ThemedLabel {
                id: versionLabel
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.state === "update-available"
                      ? qsTr("%1 → %2").arg(row.modelData.installedVersion).arg(row.modelData.version)
                      : row.modelData.version
            }
        }

        ThemedLabel {
            width: body.width
            text: row.modelData.description
            size: "sm"
        }

        ThemedLabel {
            width: body.width
            text: {
                if (row.active && row.transfer)
                    return qsTr("%1… %2%").arg(row.transfer.phase)
                                          .arg(Math.round(row.transfer.fraction * 100))
                if (row.modelData.state === "failed")
                    return row.modelData.error
                if (row.modelData.state === "needs-newer-app")
                    return qsTr("Requires Drift %1 or newer").arg(row.modelData.minAppVersion)
                var parts = []
                if (row.modelData.unofficial)
                    parts.push(qsTr("Unofficial"))
                if (row.modelData.custom) {
                    if (!row.modelData.unofficial)
                        parts.push(qsTr("Installed from file"))
                    if (row.modelData.installedSize > 0)
                        parts.push(dialog.formatSize(row.modelData.installedSize))
                    return parts.join(" · ")
                }
                parts.push(qsTr("%1 download").arg(dialog.formatSize(row.modelData.downloadSize)))
                if (row.modelData.items > 0)
                    parts.push(qsTr("%1 items").arg(row.modelData.items))
                if (row.modelData.license.length > 0)
                    parts.push(row.modelData.license)
                return parts.join(" · ")
            }
            color: row.modelData.state === "failed" ? Theme.c.addonManagerRow.foregroundError
                                                    : Theme.c.addonManagerRow.foregroundMuted
        }
    }

    Row {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        CircularProgress {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.active
            // Download and extraction each report their own 0..1, so the ring restarts
            // when the phase changes. Until a fraction arrives it spins
            // indeterminately rather than sitting at an empty ring that
            // looks like "not started".
            indeterminate: !row.transfer || row.transfer.fraction <= 0
            value: row.transfer ? row.transfer.fraction : 0
        }

        // Next to the ring, not in a hover tooltip: touch has no hover, and a
        // 28px ring cannot fit a readable number inside it.
        ThemedLabel {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.active && row.transfer && row.transfer.fraction > 0
            text: row.transfer
                  ? Math.round(row.transfer.fraction * 100) + "%"
                  : ""
            size: "sm"
            tone: "default"
            font.weight: Font.Medium
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.active
            text: qsTr("Cancel")
            variant: "ghost"
            onClicked: Addons.cancel(row.modelData.id)
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.active && row.modelData.state !== "installed"
                     && row.modelData.state !== "needs-newer-app"
            text: row.modelData.state === "update-available" ? qsTr("Update")
                : row.modelData.state === "failed" ? qsTr("Retry")
                : qsTr("Install")
            variant: "primary"
            onClicked: Addons.install(row.modelData.id)
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.active && row.modelData.installedVersion.length > 0
            text: qsTr("Remove")
            variant: "ghost"
            tooltip: qsTr("Delete this pack's downloaded data")
            onClicked: {
                dialog.pendingRemovalId = row.modelData.id
                dialog.pendingRemovalName = row.modelData.name
                confirmRemoval.open()
            }
        }
    }
}
