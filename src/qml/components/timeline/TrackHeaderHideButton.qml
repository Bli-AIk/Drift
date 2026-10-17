import QtQuick
import Drift

// Hide / bypass toggle. On a transform layer the eye bypasses the layer, not the tracks under it.
IconGlyph {
    id: hideGlyph

    property int trackIndex: -1
    property bool shown: false
    property bool trackHidden: false
    property string hideLabel: ""

    visible: shown
    glyph: trackHidden ? Theme.icons.eyeOff : Theme.icons.eye
    iconSize: 16
    iconColor: trackHidden ? Theme.destructive : Theme.mutedForeground
    anchors.verticalCenter: parent.verticalCenter

    ThemedToolTip {
        visible: hideMouse.containsMouse
        text: hideGlyph.hideLabel
    }

    Accessible.role: Accessible.CheckBox
    Accessible.name: hideLabel
    Accessible.checked: trackHidden
    Accessible.onToggleAction: hideMouse.clicked(null)

    MouseArea {
        id: hideMouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Haptics.toggle(!hideGlyph.trackHidden)
            EditorState.setTrackHidden(hideGlyph.trackIndex, !hideGlyph.trackHidden)
        }
    }
}
