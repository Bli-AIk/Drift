import QtQuick
import Drift
// One camera angle. The border marks the angle that is the program.
Rectangle {
    id: tile

    required property int index
    required property var modelData
    required property real cellWidth
    required property real cellHeight

    width: tile.cellWidth
    height: tile.cellHeight
    // Same ground as the program monitor: a tile is mostly video, and
    // PreserveAspectFit letterboxes every camera whose aspect is not the
    // cell's. Bars have to read as bars, which a light panel colour does
    // not — and the overlaid badge and filename are drawn white.
    color: Theme.c.multicamAngleTile.background
    radius: Theme.c.multicamAngleTile.radius
    border.width: modelData.active ? Theme.c.multicamAngleTile.borderWidthActive : Theme.c.multicamAngleTile.borderWidth
    border.color: modelData.active ? Theme.c.multicamAngleTile.borderActive
                                   : (tileMouse.containsMouse ? Theme.c.multicamAngleTile.borderHover
                                                              : Theme.c.multicamAngleTile.border)
    clip: true

    Behavior on border.color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Image {
        anchors.fill: parent
        anchors.margins: Theme.spacingXs
        fillMode: Image.PreserveAspectFit
        // The pixels behind this URL change on every refresh, so the
        // revision is what makes QML fetch them again.
        cache: false
        asynchronous: true
        source: modelData.hasClip && EditorState.multicamRevision > 0
                ? "image://multicam/" + tile.index + "?rev=" + EditorState.multicamRevision
                : ""
    }

    ThemedLabel {
        anchors.centerIn: parent
        visible: !tile.modelData.hasClip
        horizontalAlignment: Text.AlignHCenter
        // Sits on the tile's video ground, not on a panel, so it takes
        // the same treatment as the badge and filename above it.
        color: Theme.c.multicamAngleTile.foreground
        text: qsTr("Nothing here")
    }

    MulticamAngleBadge {
        number: tile.index + 1
        active: tile.modelData.active
    }

    MulticamAngleCaption {
        name: tile.modelData.clipName.length > 0 ? tile.modelData.clipName
                                                 : tile.modelData.label
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: EditorState.switchMulticamAngle(tile.index)
    }

    ThemedToolTip {
        visible: tileMouse.containsMouse
        text: qsTr("Switch the program to %1 (key %2)")
              .arg(tile.modelData.label).arg(tile.index + 1)
    }
}
