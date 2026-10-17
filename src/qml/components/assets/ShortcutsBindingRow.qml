import QtQuick
import Drift
// One action and its shortcut capture field.
Row {
    required property var modelData
    x: Theme.pagePadding
    width: (ListView.view ? ListView.view.width : 0) - Theme.pagePadding * 2
    spacing: Theme.spacingLg

    ListView.onPooled: captureField.capturing = false

    Text {
        width: Math.max(90, parent.width - 128)
        text: modelData.label
        color: Theme.c.shortcutsBindingRow.foreground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        wrapMode: Text.WordWrap
        anchors.verticalCenter: parent.verticalCenter
    }
    ShortcutCaptureField {
        id: captureField
        width: 120
        actionId: modelData.id
        shortcut: modelData.shortcut
    }
}
