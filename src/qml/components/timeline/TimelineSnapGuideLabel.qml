import QtQuick
import Drift

// Time chip on the snap guide, naming what the clip snapped to.
Rectangle {
    property TimelinePanel panel
    visible: parent.opacity > 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    height: snapLabel.implicitHeight + Theme.spacingSm
    width: snapLabel.implicitWidth + Theme.spacingLg
    radius: Theme.c.timelineSnapGuideLabel.radius
    color: Theme.c.timelineSnapGuideLabel.background

    Text {
        id: snapLabel
        anchors.centerIn: parent
        text: panel.formatTime(panel.snapGuideSeconds)
        color: Theme.c.timelineSnapGuideLabel.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeTiny
    }
}
