import QtQuick
import Drift

// Rule-of-thirds inside the crop frame, the usual cue for judging a reframe.
Item {
    anchors.fill: parent

    Repeater {
        model: 2
        Rectangle {
            required property int index
            width: 1
            height: parent.height
            x: parent.width * (index + 1) / 3
            color: Theme.guideWeak
        }
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            height: 1
            width: parent.width
            y: parent.height * (index + 1) / 3
            color: Theme.guideWeak
        }
    }
}
