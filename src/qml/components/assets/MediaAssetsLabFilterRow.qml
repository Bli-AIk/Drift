import QtQuick
import Drift

// Source Lab's bin filters: which items stay visible as you triage footage.
Flow {
    id: root

    property string filter: "all"

    spacing: Theme.spacingSm

    Repeater {
        model: [
            { id: "all", label: qsTr("All") },
            { id: "favorites", label: qsTr("Favorites") },
            { id: "ranges", label: qsTr("Has ranges") },
            { id: "hideRejected", label: qsTr("Hide rejected") }
        ]
        ThemedChip {
            required property var modelData
            text: modelData.label
            selected: root.filter === modelData.id
            onClicked: root.filter = modelData.id
        }
    }
}
