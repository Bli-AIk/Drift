import QtQuick
import Drift

// One preset shade on a colour parameter (Face Retouch's lip colours and the like).
Rectangle {
    id: swatch

    required property string modelData
    property bool current: false
    property int effectIndex: -1
    property string paramKey: ""

    width: 22
    height: 22
    radius: Theme.radiusSm
    color: modelData
    border.width: current ? 2 : 1
    border.color: current ? Theme.primary
                : swatchMouse.containsMouse ? Theme.panelForeground
                : Theme.panelBorder

    MouseArea {
        id: swatchMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: EditorState.setEffectColorParam(
                       EditorState.selectedTrack, EditorState.selectedClip,
                       swatch.effectIndex, swatch.paramKey, swatch.modelData)
    }
    ThemedToolTip {
        visible: swatchMouse.containsMouse
        text: swatch.modelData
    }
}
