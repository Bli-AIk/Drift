import QtQuick
import Drift

Rectangle {
    id: root

    readonly property var lab: EditorState.sourceLab

    implicitHeight: column.height + Theme.spacingLg * 2
    radius: Theme.c.sourceLabPanel.cardRadius
    color: Theme.c.sourceLabPanel.cardBackground
    border.width: Theme.c.sourceLabPanel.cardBorderWidth
    border.color: Theme.c.sourceLabPanel.cardBorder

    function formatEta(seconds) {
        const total = Math.max(0, Math.round(seconds))
        const h = Math.floor(total / 3600)
        const m = Math.floor(total / 60) % 60
        const s = total % 60
        if (h > 0)
            return qsTr("%1 h %2 min").arg(h).arg(m)
        if (m > 0)
            return qsTr("%1 min %2 s").arg(m).arg(s)
        return qsTr("%1 s").arg(s)
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingMd

        ThemedProgressBar {
            width: parent.width
            value: root.lab.progress
        }

        Item {
            width: parent.width
            height: cancelButton.height

            ThemedLabel {
                anchors.left: parent.left
                anchors.right: cancelButton.left
                anchors.rightMargin: Theme.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.lab.etaSeconds >= 0
                      ? qsTr("%1 - %2 left").arg(root.lab.status).arg(root.formatEta(root.lab.etaSeconds))
                      : root.lab.status
            }
            ThemedButton {
                id: cancelButton
                anchors.right: parent.right
                variant: "secondary"
                text: qsTr("Cancel")
                onClicked: root.lab.cancel()
            }
        }
    }
}
