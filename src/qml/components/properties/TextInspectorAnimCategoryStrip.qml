import QtQuick
import Drift

Flickable {
    id: root
    property var inspector
    width: parent.width
    height: Theme.controlHeightSm
    contentWidth: categoryRow.width
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    interactive: contentWidth > width
    visible: inspector.animCategories.length > 1

    Row {
        id: categoryRow
        height: parent.height
        spacing: Theme.spacingSm

        ThemedChip {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("All")
            variant: "secondary"
            selected: inspector.animCategory.length === 0
            onClicked: inspector.animCategory = ""
        }

        Repeater {
            model: inspector.animCategories
            delegate: ThemedChip {
                required property var modelData
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                variant: "secondary"
                accentColor: Theme.categoryColor(index)
                selected: inspector.animCategory === modelData.id
                onClicked: inspector.animCategory = modelData.id
            }
        }
    }
}
