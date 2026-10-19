import QtQuick
import Drift

// The 2D / 3D switch: an icon pill that slides between the two. 2D shows the scene camera's
// picture, which is what exports; 3D shows the world from a free viewpoint with the camera drawn
// in it, which is where the camera and depth are arranged.
Rectangle {
    id: modeSwitch

    readonly property var modes: [
        { value: "2d", glyph: Theme.icons.monitor, label: qsTr("Camera Output"),
          tip: qsTr("The camera's picture, as it exports. Clips move and snap on the canvas.") },
        { value: "3d", glyph: Theme.icons.box, label: qsTr("3D Scene"),
          tip: qsTr("The scene from a free viewpoint, with the camera in it. Middle- or right-drag orbits, Shift pans, the wheel zooms, and the corner pad steps the view.") }
    ]
    readonly property int current: EditorState.preview.mode === "3d" ? 1 : 0
    readonly property real inset: 2
    readonly property real segmentWidth: Theme.iconButtonSize

    width: segmentWidth * modes.length + inset * 2
    height: Theme.iconButtonSize + inset * 2
    radius: height / 2
    // The same tokens as the app's other segmented toggles (ThemedToggleButton): the track is an
    // unchecked control, the pill a checked one.
    color: Theme.c.previewModeSwitch.background
    border.width: Theme.c.previewModeSwitch.borderWidth
    border.color: Theme.c.previewModeSwitch.border

    PreviewModeSwitchPill {
        inset: modeSwitch.inset
        current: modeSwitch.current
        segmentWidth: modeSwitch.segmentWidth
    }

    Row {
        x: modeSwitch.inset
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: modeSwitch.modes
            delegate: PreviewModeSwitchSegment {
                current: modeSwitch.current
                segmentWidth: modeSwitch.segmentWidth
                onChosen: (value) => EditorState.preview.mode = value
            }
        }
    }
}
