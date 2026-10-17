import QtQuick
import Drift

Column {
    id: recents
    property var items
    signal openRecentRequested(string path)
    width: parent.width
    spacing: Theme.spacingMd

    Text {
        text: qsTr("Recent Projects")
        color: Theme.c.startScreenRecents.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Font.Medium
    }

    ThemedLabel {
        width: parent.width
        visible: items.length === 0
        wrapMode: Text.WordWrap
        text: qsTr("Nothing here yet — projects you save will show up in this list.")
    }

    ListView {
        id: recentList
        width: parent.width
        // Non-interactive: the outer Flickable scrolls the whole page, so this
        // grows to its full content height rather than clipping and needing a
        // second scroll gesture.
        height: contentHeight
        spacing: Theme.spacingSm
        visible: items.length > 0
        interactive: false
        model: items
        delegate: StartScreenProjectRow {
                        onOpenRequested: (path) => recents.openRecentRequested(path)
                    }
    }
}
