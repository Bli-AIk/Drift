import QtQuick
import Drift

// The kept rectangle, with the rule-of-thirds cue for judging a reframe.
Rectangle {
    color: "transparent"
    border.width: Theme.borderWidthFocus
    border.color: Theme.primary

    Repeater {
        model: 2
        Rectangle {
            width: 1
            height: parent.height
            x: parent.width * (index + 1) / 3
            color: Theme.guideWeak
        }
    }
    Repeater {
        model: 2
        Rectangle {
            height: 1
            width: parent.width
            y: parent.height * (index + 1) / 3
            color: Theme.guideWeak
        }
    }
}
