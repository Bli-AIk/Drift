import QtQuick
import Drift

Rectangle {
    required property int index
    required property var modelData
    property int highlightIndex
    property var kindLabels
    signal activated(int rowIndex)
    id: resultRow

    readonly property bool runnable: modelData.run !== null && modelData.run !== undefined
    readonly property string detail: [modelData.sub, modelData.hint].filter(s => s && s.length > 0)
                                                                    .join("  ·  ")

    width: ListView.view.width
    height: column.implicitHeight + Theme.spacingMd * 2
    radius: Theme.radiusSm
    color: rowMouse.containsMouse || highlightIndex === index ? Theme.popoverHover : "transparent"
    opacity: modelData.enabled ? 1.0 : 0.5

    Column {
        id: column
        anchors.left: parent.left
        anchors.right: badges.left
        anchors.leftMargin: Theme.spacingLg
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs

        Text {
            width: parent.width
            text: resultRow.modelData.label
            elide: Text.ElideRight
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }

        Text {
            width: parent.width
            visible: text.length > 0
            text: resultRow.detail
            elide: Text.ElideRight
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }

    Row {
        id: badges
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingLg
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingLg

        Text {
            visible: text.length > 0
            text: resultRow.modelData.shortcut
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }

        Text {
            text: kindLabels[resultRow.modelData.kind] || ""
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: resultRow.runnable && resultRow.modelData.enabled ? Qt.PointingHandCursor
                                                                      : Qt.ArrowCursor
        onClicked: resultRow.activated(resultRow.index)
    }
}
