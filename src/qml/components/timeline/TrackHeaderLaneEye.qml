import QtQuick
import Drift

// Eye for one nested adjustment lane, level with that lane's strip.
Item {
    id: laneEye

    property TrackHeaderColumn column
    required property var modelData
    readonly property bool laneHidden: !!column.tracks[modelData] && column.tracks[modelData].hidden === true

    width: 16
    height: Theme.adjustmentLaneHeight

    IconGlyph {
        anchors.centerIn: parent
        glyph: laneEye.laneHidden ? Theme.icons.eyeOff : Theme.icons.eye
        iconSize: 14
        iconColor: laneEye.laneHidden ? Theme.destructive : Theme.mutedForeground

        ThemedToolTip {
            visible: laneEyeMouse.containsMouse
            text: laneEye.laneHidden ? qsTr("Turn adjustment on") : qsTr("Turn adjustment off")
        }

        Accessible.role: Accessible.CheckBox
        Accessible.name: laneEye.laneHidden ? qsTr("Turn adjustment on") : qsTr("Turn adjustment off")
        Accessible.checked: laneEye.laneHidden
        Accessible.onToggleAction: laneEyeMouse.clicked(null)
    }

    MouseArea {
        id: laneEyeMouse
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Haptics.toggle(!laneEye.laneHidden)
            EditorState.setTrackHidden(laneEye.modelData, !laneEye.laneHidden)
        }
    }
}
