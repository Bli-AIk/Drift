import QtQuick
import Drift

// The kept rectangle, with the rule-of-thirds cue for judging a reframe.
Rectangle {
    color: "transparent"
    border.width: Theme.c.androidCropFrame.borderWidth
    border.color: Theme.c.androidCropFrame.border

    Repeater {
        model: 2
        Rectangle {
            width: Theme.c.androidCropFrame.guideWidth
            height: parent.height
            x: parent.width * (index + 1) / 3
            color: Theme.c.androidCropFrame.guide
        }
    }
    Repeater {
        model: 2
        Rectangle {
            height: Theme.c.androidCropFrame.guideWidth
            width: parent.width
            y: parent.height * (index + 1) / 3
            color: Theme.c.androidCropFrame.guide
        }
    }
}
