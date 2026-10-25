import QtQuick
import Drift

Rectangle {
    id: block

    required property var panel
    required property int index

    readonly property var timeView: panel.timeView
    readonly property var cue: panel.liveCues[index]
    readonly property bool selected: !!panel.selectedMap[index]
    readonly property bool active: index === panel.activeCue
    readonly property bool editing: index === panel.editingIndex
    readonly property real x0: timeView.xFor(panel.clipStart + cue.start)
    readonly property real x1: timeView.xFor(panel.clipStart + cue.end)
    readonly property bool empty: !cue.text || cue.text.length === 0

    visible: x1 > -4 && x0 < panel.laneWidth + 4
    x: x0
    y: 4
    width: Math.max(3, x1 - x0)
    height: panel.cueAreaHeight - 8
    radius: Theme.c.subtitleLaneCue.radius
    color: Theme.c.subtitleLaneCue.background
    opacity: selected ? 1 : (active ? Theme.c.subtitleLaneCue.opacityActive : Theme.c.subtitleLaneCue.opacityIdle)
    border.width: selected ? Theme.c.subtitleLaneCue.borderWidth : 0
    border.color: Theme.c.subtitleLaneCue.border
    clip: true
    z: selected ? 2 : 1

    Rectangle {
        visible: block.selected
        width: Math.min(6, block.width / 4)
        height: parent.height
        color: Theme.c.subtitleLaneCue.grip
        opacity: 0.6
    }

    Rectangle {
        visible: block.selected
        x: parent.width - width
        width: Math.min(6, block.width / 4)
        height: parent.height
        color: Theme.c.subtitleLaneCue.grip
        opacity: 0.6
    }

    Text {
        id: indexLabel
        x: 6
        y: 3
        visible: !block.editing && block.width > 24
        text: block.index + 1
        color: Theme.c.subtitleLaneCue.index
        opacity: Theme.c.subtitleLaneCue.opacityIndex
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    Text {
        visible: !block.editing
        x: 6
        y: indexLabel.visible ? indexLabel.y + indexLabel.height + 1 : 3
        width: parent.width - 12
        height: parent.height - y - 3
        wrapMode: Text.Wrap
        elide: Text.ElideRight
        clip: true
        text: block.empty ? qsTr("(empty)") : block.cue.text
        color: Theme.c.subtitleLaneCue.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        font.italic: block.empty
    }
}
