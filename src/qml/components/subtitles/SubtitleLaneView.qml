pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Drift

Item {
    id: root

    required property var panel

    readonly property var timeView: panel.timeView
    readonly property alias surface: surface
    readonly property real cueAreaHeight: Math.floor(laneArea.height * 0.6)
    readonly property real scrollPadding: width * 0.25
    readonly property real scrollMin: timeView.clipStart * timeView.pxPerSecond - scrollPadding
    readonly property real scrollTotal: Math.max(1, timeView.clipDuration * timeView.pxPerSecond + 2 * scrollPadding)
    readonly property int cueCount: panel.liveCues.length

    Binding {
        target: root.panel
        property: "cueAreaHeight"
        value: root.cueAreaHeight
    }

    Binding {
        target: root.panel
        property: "laneWidth"
        value: root.width
    }

    KeyframesRuler {
        id: ruler
        width: parent.width
        timeView: root.timeView
    }

    Item {
        id: laneArea
        y: ruler.height
        width: parent.width
        height: parent.height - y
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Theme.c.subtitleLane.background
        }

        Rectangle {
            readonly property real edge0: root.timeView.xFor(root.timeView.clipStart)
            readonly property real edge1: root.timeView.xFor(root.timeView.clipStart + root.timeView.clipDuration)
            x: Math.max(0, edge0)
            width: Math.max(0, Math.min(laneArea.width, edge1) - x)
            height: parent.height
            color: Theme.c.subtitleLane.clipSpan
            opacity: Theme.c.subtitleLane.opacityClipSpan
        }

        Rectangle {
            y: root.cueAreaHeight
            width: parent.width
            height: parent.height - y
            color: Theme.c.subtitleLane.waveformBand
            opacity: Theme.c.subtitleLane.opacityWaveformBand
        }

        SubtitleLaneWaveform {
            y: root.cueAreaHeight
            height: laneArea.height - y
            panel: root.panel
            viewWidth: laneArea.width
        }

        Repeater {
            model: Math.max(0, root.cueCount - 1)

            delegate: Rectangle {
                id: gap

                required property int index

                readonly property real g0: root.timeView.xFor(root.panel.clipStart + root.panel.liveCues[index].end)
                readonly property real g1: root.timeView.xFor(root.panel.clipStart + root.panel.liveCues[index + 1].start)

                visible: g1 > g0 && g1 > 0 && g0 < laneArea.width
                x: g0
                width: Math.max(0, g1 - g0)
                height: root.cueAreaHeight
                color: Theme.c.subtitleLane.gapShade
                opacity: Theme.c.subtitleLane.opacityGap
            }
        }

        Repeater {
            model: root.cueCount

            delegate: SubtitleLaneCueBlock {
                panel: root.panel
            }
        }

        Repeater {
            model: root.cueCount

            delegate: Rectangle {
                id: overlap

                required property int index

                readonly property var prev: index > 0 ? root.panel.liveCues[index - 1] : null
                readonly property var cur: root.panel.liveCues[index]
                readonly property real o0: root.timeView.xFor(root.panel.clipStart + cur.start)
                readonly property real o1: root.timeView.xFor(root.panel.clipStart + (prev ? Math.min(prev.end, cur.end) : cur.start))

                visible: !!prev && o1 > o0
                x: o0
                y: 4
                width: Math.max(2, o1 - o0)
                height: root.cueAreaHeight - 8
                z: 3
                color: Theme.c.subtitleLaneCue.overlap
                opacity: Theme.c.subtitleLaneCue.opacityOverlap
            }
        }

        Text {
            visible: root.cueCount === 0
            x: 0
            width: parent.width
            height: root.cueAreaHeight
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: qsTr("Drag on the lane to add a cue")
            color: Theme.c.subtitleLane.foregroundMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
        }

        Rectangle {
            visible: surface.creating
            x: root.timeView.xFor(root.panel.clipStart + surface.createStart)
            y: 4
            width: Math.max(1, root.timeView.xFor(root.panel.clipStart + surface.createEnd) - x)
            height: root.cueAreaHeight - 8
            radius: Theme.c.subtitleLaneCue.radius
            color: Theme.c.subtitleLane.ghost
            opacity: Theme.c.subtitleLane.opacityGhost
            border.width: Theme.c.subtitleLaneCue.borderWidth
            border.color: Theme.c.subtitleLaneCue.border
            z: 4
        }

        SubtitleLaneInteraction {
            id: surface
            anchors.fill: parent
            anchors.bottomMargin: hBar.height
            panel: root.panel
        }

        KeyframesMarquee {
            visible: surface.marqueeActive && width > 2
            x: surface.marqueeX
            y: 0
            width: surface.marqueeWidth
            height: root.cueAreaHeight
        }

        KeyframesPlayheadLine {
            timeView: root.timeView
        }

        ThemedTextArea {
            id: editor

            readonly property var cue: root.panel.editingIndex >= 0 ? root.panel.liveCues[root.panel.editingIndex] : null
            readonly property real blockX: cue ? root.timeView.xFor(root.panel.clipStart + cue.start) : 0

            visible: !!cue
            width: Math.min(laneArea.width, Math.max(220, cue ? root.timeView.xFor(root.panel.clipStart + cue.end) - blockX : 0))
            x: Math.max(0, Math.min(blockX, laneArea.width - width))
            y: 4
            height: root.cueAreaHeight - 8
            z: 6
            topPadding: Theme.spacingSm
            bottomPadding: Theme.spacingSm
            leftPadding: Theme.spacingMd
            rightPadding: Theme.spacingMd
            placeholderText: qsTr("Cue text")

            onVisibleChanged: {
                if (!visible)
                    return
                text = cue ? cue.text : ""
                forceActiveFocus()
                selectAll()
            }
            onActiveFocusChanged: {
                if (!activeFocus && root.panel.editingIndex >= 0)
                    root.panel.commitEdit(text)
            }
            Keys.onPressed: (event) => {
                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        && !(event.modifiers & Qt.ShiftModifier)) {
                    root.panel.commitEdit(text)
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.panel.cancelEdit()
                    event.accepted = true
                }
            }
        }

        AppScrollBar {
            id: hBar
            orientation: Qt.Horizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            policy: ScrollBar.AsNeeded
            size: Math.min(1, root.width / root.scrollTotal)
            position: Math.max(0, Math.min(1 - size, (root.timeView.contentX - root.scrollMin) / root.scrollTotal))
            onPositionChanged: {
                if (pressed)
                    root.timeView.contentX = root.scrollMin + position * root.scrollTotal
            }
        }
    }
}
