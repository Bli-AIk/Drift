import QtQuick
import Drift

// The aspect morph is what makes a ratio change legible: the inner rect eases
// between the outgoing size and the one Done will commit.
Rectangle {
    id: aspectBox

    property int outWidth: 1
    property int outHeight: 1
    property string aspectLabel: ""

    width: 72
    height: 72
    radius: Theme.c.androidLayoutSummarySwatch.radius
    color: Theme.c.androidLayoutSummarySwatch.background
    border.width: Theme.c.androidLayoutSummarySwatch.borderWidth
    border.color: Theme.c.androidLayoutSummarySwatch.border

    readonly property real scaleToBox:
        Math.min(width / Math.max(1, aspectBox.outWidth),
                 height / Math.max(1, aspectBox.outHeight))

    Rectangle {
        anchors.centerIn: parent
        width: Math.max(8, aspectBox.outWidth * aspectBox.scaleToBox)
        height: Math.max(8, aspectBox.outHeight * aspectBox.scaleToBox)
        radius: Theme.c.androidLayoutSummarySwatch.innerRadius
        color: Theme.c.androidLayoutSummarySwatch.innerBackground
        border.width: Theme.c.androidLayoutSummarySwatch.innerBorderWidth
        border.color: Theme.c.androidLayoutSummarySwatch.innerBorder

        // A morph between two aspect ratios, not an entrance.
        Behavior on width {
            NumberAnimation {
                duration: Theme.durationBase
                easing.type: Theme.easingInOut
            }
        }
        Behavior on height {
            NumberAnimation {
                duration: Theme.durationBase
                easing.type: Theme.easingInOut
            }
        }

        Text {
            anchors.centerIn: parent
            text: aspectBox.aspectLabel
            color: Theme.c.androidLayoutSummarySwatch.foreground
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
        }
    }
}
