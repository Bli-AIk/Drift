import QtQuick
import Drift

Item {
    property var host
    property Item plotItem: null
    required property var modelData
    anchors.fill: parent

    Rectangle {
        width: parent.width
        height: Theme.c.speedCurveGridLine.lineWidth
        y: host.yForSpeed(modelData, plotItem.height)
        color: modelData === 1 ? Theme.c.speedCurveGridLine.emphasis : Theme.c.speedCurveGridLine.line
        opacity: modelData === 1 ? Theme.c.speedCurveGridLine.emphasisOpacity : Theme.c.speedCurveGridLine.opacity
    }

    Text {
        x: 2
        y: host.yForSpeed(modelData, plotItem.height) - height - 1
        text: modelData + "×"
        color: Theme.c.speedCurveGridLine.foregroundMuted
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }
}
