import QtQuick
import Drift

Text {
    id: note

    required property var selected

    width: parent ? parent.width : 0
    visible: note.selected !== null && !(note.selected.inLibrary)
    topPadding: Theme.spacingSm
    bottomPadding: Theme.spacingSm
    wrapMode: Text.WordWrap
    text: note.selected && note.selected.builtIn
          ? qsTr("Built-in sets can't be changed. Duplicate one to make an editable copy.")
          : qsTr("This set came with the project. Save it to your guide sets to edit it.")
    color: Theme.c.guidesPopoverReadOnlyNote.foreground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs
}
