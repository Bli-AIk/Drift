import QtQuick
import Drift

// A bookmark on the ruler lane. Tap jumps; hold opens the menu. The flag is
// 10px; the target is a fingertip, widened sideways only so it cannot reach
// down over the first track and eat the start of a pan there.
Item {
    id: bookmarkFlag

    required property int index
    required property var modelData
    property real pxPerSecond: 1
    // ThemedContextMenu owned by the timeline. The flag fills its index and label.
    required property var menu

    x: modelData.seconds * bookmarkFlag.pxPerSecond - width / 2
    width: 10
    height: parent ? parent.height : 0

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -6
        width: 1
        height: parent.height + 6
        color: Theme.primary
        opacity: 0.7
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        rotation: 45
        radius: 1
        color: Theme.primary
    }

    // A project marked up on desktop arrived as a row of
    // anonymous diamonds; the label is the whole point of
    // a bookmark. Overflows the 10px flag deliberately.
    Text {
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        text: bookmarkFlag.modelData.label
        color: Theme.mutedForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeTiny
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -14
        anchors.rightMargin: -14
        preventStealing: true
        pressAndHoldInterval: 400

        property bool held: false

        onPressed: held = false
        onPressAndHold: {
            held = true
            Haptics.pickUp()
            bookmarkFlag.menu.bookmarkIndex = bookmarkFlag.index
            bookmarkFlag.menu.bookmarkLabel = bookmarkFlag.modelData.label
            bookmarkFlag.menu.popup()
        }
        onClicked: if (!held) {
            Haptics.select()
            EditorState.goToBookmark(bookmarkFlag.index)
        }
    }
}
