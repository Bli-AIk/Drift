import QtQuick
import Drift

Rectangle {
    required property var modelData
    property var transfers
    id: row

    readonly property var transfer: transfers[modelData.id]
    readonly property bool installed:
        Addons.catalog.some(function (a) {
            return a.id === row.modelData.id && a.installedVersion.length > 0
        })

    width: parent ? parent.width : 0
    height: rowBody.implicitHeight + Theme.spacingXl
    radius: Theme.radiusMd
    color: Theme.panelSecondaryBg
    border.width: Theme.borderWidth
    border.color: Theme.panelSecondaryBorder

    Column {
        id: rowBody
        anchors.left: parent.left
        anchors.right: rowActions.left
        anchors.leftMargin: Theme.spacingXl
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs

        ThemedLabel {
            width: rowBody.width
            text: row.modelData.name
            tone: "default"
            size: "sm"
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        ThemedLabel {
            width: rowBody.width
            text: {
                if (row.transfer)
                    return qsTr("%1… %2%").arg(row.transfer.phase)
                                          .arg(Math.round(row.transfer.fraction * 100))
                var parts = [row.modelData.id]
                if (row.modelData.version.length > 0)
                    parts.push(qsTr("used version %1").arg(row.modelData.version))
                return parts.join(" · ")
            }
            elide: Text.ElideRight
        }
    }

    Row {
        id: rowActions
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        CircularProgress {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.transfer !== undefined && !row.installed
            indeterminate: !row.transfer || row.transfer.fraction <= 0
            value: row.transfer ? row.transfer.fraction : 0
        }

        ThemedButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: !row.installed && row.transfer === undefined
            text: qsTr("Install")
            variant: "primary"
            onClicked: Addons.install(row.modelData.id)
        }

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            visible: row.installed
            glyph: Theme.icons.success
            iconSize: Theme.iconSizeMd
            iconColor: Theme.primary
        }
    }
}
