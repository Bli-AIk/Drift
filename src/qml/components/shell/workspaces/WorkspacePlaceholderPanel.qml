import QtQuick
import Drift

PanelFrame {
    id: root
    property string label: ""

    ThemedLabel {
        anchors.centerIn: parent
        size: "base"
        text: qsTr("%1 — coming soon").arg(root.label)
    }
}
