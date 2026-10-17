import QtQuick
import Drift

// The shorter side, which the upscale suggestion is judged by.
Rectangle {
    id: chip

    required property color tint
    required property string grade

    width: gradeText.implicitWidth + 24
    radius: height / 2
    color: chip.tint

    Text {
        id: gradeText
        anchors.centerIn: parent
        text: chip.grade
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeSm
        font.weight: Font.Bold
        color: "#1a1206"
    }
}
