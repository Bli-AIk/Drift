import QtQuick
import Drift

Text {
    property var inspector
    visible: inspector.clipKind === "subtitle"
    width: parent.width
    text: qsTr("Plays for every caption")
    color: Theme.mutedForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs
}
