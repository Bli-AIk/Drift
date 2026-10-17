import QtQuick
import Drift

Column {
    spacing: 2

    Text {
        text: "Drift"
        color: Theme.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 22
        font.weight: Font.Bold
    }

    Text {
        text: qsTr("Create polished videos fast")
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
    }
}
