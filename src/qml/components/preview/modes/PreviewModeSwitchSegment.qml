import QtQuick
import Drift
// One mode of the 2D / 3D switch: icon, hit target and tooltip.
Item {
    id: segment

    required property var modelData
    required property int index
    required property int current
    required property real segmentWidth

    readonly property bool selected: segment.index === segment.current

    width: segment.segmentWidth
    height: Theme.iconButtonSize

    signal chosen(string value)

    Accessible.role: Accessible.RadioButton
    Accessible.name: modelData.label
    Accessible.checked: selected

    IconGlyph {
        anchors.centerIn: parent
        glyph: segment.modelData.glyph
        iconSize: Theme.iconSizeBase
        iconColor: segment.selected ? Theme.c.previewModeSwitchSegment.iconSelected
                                    : segmentArea.containsMouse ? Theme.c.previewModeSwitchSegment.iconHover
                                                                : Theme.c.previewModeSwitchSegment.icon

        Behavior on iconColor {
            ColorAnimation { duration: Theme.durationBase; easing.type: Theme.easing }
        }
    }

    MouseArea {
        id: segmentArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: segment.chosen(segment.modelData.value)
    }

    ThemedToolTip {
        text: segment.modelData.tip
        visible: segmentArea.containsMouse
    }
}
