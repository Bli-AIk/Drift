import QtQuick
import Drift

// Grade on the left, output size on the right. Orange under the threshold, green once it clears it.
Rectangle {
    id: pill

    required property bool suggestUpscale
    required property int shortSide
    required property int outputWidth
    required property int outputHeight

    readonly property color tint: pill.suggestUpscale ? Theme.warning : Theme.constructive
    readonly property color ink: Theme.darkMode ? tint : Qt.darker(tint, 1.7)

    width: pillRow.width + 2
    height: 38
    radius: height / 2
    color: Qt.rgba(tint.r, tint.g, tint.b, 0.12)
    border.width: 1
    border.color: Qt.rgba(tint.r, tint.g, tint.b, 0.55)

    Row {
        id: pillRow
        anchors.centerIn: parent

        MediaPreviewGradeChip {
            tint: pill.tint
            grade: qsTr("%1p").arg(pill.shortSide)
            height: pill.height - 2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 14
            rightPadding: 18
            text: pill.outputWidth + " × " + pill.outputHeight
            font.family: Theme.monoFontFamily
            font.pixelSize: 18
            font.weight: Font.Medium
            color: pill.ink
        }
    }
}
