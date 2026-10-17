import QtQuick
import Drift

Text {
    property bool available: false
    property int matchCount: 0
    property string query: ""
    visible: available && matchCount === 0
    text: qsTr("No emoji match “%1”.").arg(query)
    color: Theme.c.emojiPickerEmptyLabel.foregroundMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeSm
    elide: Text.ElideRight
}
