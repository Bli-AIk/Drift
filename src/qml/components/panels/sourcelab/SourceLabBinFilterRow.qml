import QtQuick
import Drift

// Source Lab's bin filters: triage state, and optionally one media kind.
Flow {
    id: root

    property string filter: "all"
    property string kind: ""

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

    Repeater {
        model: [
            { id: "video", label: qsTr("Video") },
            { id: "audio", label: qsTr("Audio") },
            { id: "image", label: qsTr("Image") }
        ]
        ThemedChip {
            required property var modelData
            text: modelData.label
            selected: root.kind === modelData.id
            onClicked: root.kind = root.kind === modelData.id ? "" : modelData.id
        }
    }
}
