import QtQuick
import Drift
import "SourceLabTime.js" as SourceLabTime

// Play, step and shuttle controls, the timecode field and the In/Out readout.
Flow {
    id: root

    readonly property var preview: EditorState.assetPreview
    readonly property var lab: EditorState.sourceLab
    readonly property real fps: root.preview.fps
    readonly property real trimIn: root.lab.recipe.trimIn ?? 0
    readonly property real trimOut: (root.lab.recipe.trimOut ?? -1) < 0
                                    ? root.lab.durationSeconds : root.lab.recipe.trimOut

    signal togglePlayRequested()

    spacing: Theme.spacingMd

    Row {
        spacing: Theme.spacingSm

        IconButton {
            glyph: Theme.icons.rewind
            tooltip: qsTr("Play backward (J)")
            active: root.preview.shuttleRate < 0
            onClicked: root.preview.shuttleReverse()
        }
        IconButton {
            glyph: Theme.icons.stepBack
            tooltip: qsTr("Previous frame (Left)")
            onClicked: root.preview.stepFrames(-1)
        }
        IconButton {
            glyph: root.preview.playing ? Theme.icons.pause : Theme.icons.play
            tooltip: root.preview.playing ? qsTr("Pause (Space)") : qsTr("Play (Space)")
            onClicked: root.togglePlayRequested()
        }
        IconButton {
            glyph: Theme.icons.stepForward
            tooltip: qsTr("Next frame (Right)")
            onClicked: root.preview.stepFrames(1)
        }
        IconButton {
            glyph: Theme.icons.fastForward
            tooltip: qsTr("Play forward, faster each press (L)")
            active: root.preview.shuttleRate > 1
            onClicked: root.preview.shuttleForward()
        }
    }

    ThemedLabel {
        width: 44
        height: Theme.controlHeight
        verticalAlignment: Text.AlignVCenter
        font.family: Theme.monoFontFamily
        tone: "default"
        text: root.preview.shuttleRate === 0 ? ""
              : (root.preview.shuttleRate < 0 ? "◀ " : "▶ ") + Math.abs(root.preview.shuttleRate) + "x"
    }

    SourceLabTimecodeField {
        seconds: root.preview.position
        fps: root.fps
        duration: root.lab.durationSeconds
        onSeekRequested: (target) => root.preview.seek(root.preview.snapToFrame(target))
    }

    ThemedLabel {
        height: Theme.controlHeight
        verticalAlignment: Text.AlignVCenter
        font.family: Theme.monoFontFamily
        size: "sm"
        text: qsTr("In %1   Out %2   Dur %3")
              .arg(SourceLabTime.format(root.trimIn, root.fps))
              .arg(SourceLabTime.format(root.trimOut, root.fps))
              .arg(SourceLabTime.format(Math.max(0, root.trimOut - root.trimIn), root.fps))
    }
}
