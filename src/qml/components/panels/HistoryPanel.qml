import QtQuick
import QtQuick.Controls.Basic
import Drift

PanelFrame {
    id: root

    readonly property var entries: [qsTr("Start")].concat(EditorState.undoHistory)
    readonly property int current: EditorState.undoIndex

    function followCurrent() {
        list.positionViewAtIndex(root.current, ListView.Contain)
    }

    onCurrentChanged: Qt.callLater(root.followCurrent)

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: qsTr("History")
    }

    EmptyState {
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        visible: EditorState.undoHistory.length === 0
        glyph: Theme.icons.undo
        title: qsTr("Nothing to undo yet. Your edits will be listed here.")
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: EditorState.undoHistory.length > 0
        clip: true
        model: root.entries
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AppScrollBar {}
        Component.onCompleted: root.followCurrent()

        delegate: Rectangle {
            required property int index
            required property string modelData
            readonly property bool isCurrent: index === root.current

            width: ListView.view.width
            height: 28
            color: isCurrent ? Theme.accent : (hover.hovered ? Theme.popoverHover : "transparent")

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.pagePadding
                anchors.rightMargin: Theme.pagePadding
                anchors.verticalCenter: parent.verticalCenter
                text: modelData
                elide: Text.ElideRight
                color: isCurrent ? Theme.accentForeground : Theme.foreground
                opacity: index > root.current ? 0.45 : 1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.italic: index === 0
            }

            HoverHandler { id: hover }
            TapHandler {
                enabled: !isCurrent
                onTapped: EditorState.setUndoIndex(index)
            }
        }
    }
}
