import QtQuick
import Drift

Item {
    property var host
    property Item plotItem: null
    required property var modelData
    anchors.fill: parent

    Rectangle {
        width: parent.width
        height: 1
        y: host.yForSpeed(modelData, plotItem.height)
        color: modelData === 1 ? Theme.panelSecondaryForeground : Theme.panelBorder
        opacity: modelData === 1 ? 0.6 : 0.35
    }

    Text {
        x: 2
        y: host.yForSpeed(modelData, plotItem.height) - height - 1
        text: modelData + "×"
        color: Theme.mutedForeground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
