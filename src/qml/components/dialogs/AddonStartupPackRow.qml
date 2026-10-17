import QtQuick
import Drift

// One pack row in the startup installer: name plus either a description or a version step.
Rectangle {
    id: row

    required property var modelData
    property var transfers
    property bool updateMode: false
    readonly property var transfer: transfers ? transfers[modelData.id] : null

    width: parent ? parent.width : 0
    height: rowBody.implicitHeight + Theme.spacingXl
    radius: Theme.c.addonStartupPackRow.radius
    color: Theme.c.addonStartupPackRow.background
    border.width: Theme.c.addonStartupPackRow.borderWidth
    border.color: Theme.c.addonStartupPackRow.border

    Column {
        id: rowBody
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingXl
        anchors.rightMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs

        ThemedLabel {
            width: parent.width
            text: row.modelData.name
            tone: "default"
            size: "sm"
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        ThemedLabel {
            width: parent.width
            text: {
                if (row.transfer)
                    return qsTr("%1… %2%").arg(row.transfer.phase)
                                          .arg(Math.round(row.transfer.fraction * 100))
                if (row.updateMode)
                    return qsTr("%1 → %2").arg(row.modelData.installedVersion)
                                          .arg(row.modelData.version)
                return row.modelData.description || row.modelData.id
            }
            elide: Text.ElideRight
        }
    }
}
