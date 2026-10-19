import QtQuick
import Drift

Column {
    spacing: 2

    Text {
        text: "Drift"
        color: Theme.c.androidHomeWordmark.foreground
        font.family: Theme.fontFamily
        font.pixelSize: 22
        font.weight: Font.Bold
    }

    Text {
        text: qsTr("Create polished videos fast")
        color: Theme.c.androidHomeWordmark.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
    }
}
