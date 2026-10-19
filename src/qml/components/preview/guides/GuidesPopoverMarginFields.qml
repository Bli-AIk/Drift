import QtQuick
import Drift
// Left, right, top and bottom margins of a rectangle guide.
Grid {
    id: margins

    required property var item
    signal edited(string key, real fraction)

    columns: 2
    columnSpacing: Theme.spacingSm
    rowSpacing: Theme.spacingXs
    verticalItemAlignment: Grid.AlignVCenter
    visible: margins.item.kind === "rect"

    Repeater {
        model: [
            { key: "left", label: qsTr("Left") },
            { key: "right", label: qsTr("Right") },
            { key: "top", label: qsTr("Top") },
            { key: "bottom", label: qsTr("Bottom") }
        ]
        Row {
            required property var modelData
            spacing: Theme.spacingSm

            ThemedLabel {
                width: 44
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
            }
            GuidesPopoverPercentField {
                to: 50
                fraction: margins.item[modelData.key]
                onCommitted: f => margins.edited(modelData.key, f)
            }
        }
    }
}
