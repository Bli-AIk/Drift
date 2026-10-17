import QtQuick
import Drift

// Text / Style / Animate switch for the text inspector.
Row {
    id: root

    property string textTab: "text"
    signal tabSelected(string tabId)

    spacing: Theme.spacingSm

    Repeater {
        model: [
            { "id": "text", "label": qsTr("Text") },
            { "id": "style", "label": qsTr("Style") },
            { "id": "animate", "label": qsTr("Animate") }
        ]
        delegate: ThemedToggleButton {
            required property var modelData
            width: (root.width - root.spacing * 2) / 3
            text: modelData.label
            checked: root.textTab === modelData.id
            onClicked: root.tabSelected(modelData.id)
        }
    }
}
