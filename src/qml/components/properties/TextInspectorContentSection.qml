import QtQuick
import Drift

CollapsibleSection {
    id: root
    property var inspector
    property alias contentField: textContentField
    width: parent.width
    title: qsTr("Text")
    collapsible: false
    showSeparator: false
    visible: inspector.clipKind === "text"

    ThemedTextArea {
        id: textContentField
        width: parent.width
        height: inspector.contentFieldHeight
        clip: true
        placeholderText: qsTr("Type your text…")
        onEditingFinished: inspector.applyText()
    }

    TextContentResizeGrip {
                fieldHeight: inspector.contentFieldHeight
                measureItem: inspector
                onHeightEdited: function(height) { inspector.contentFieldHeight = height }
            }

    ThemedButton {
        width: parent.width
        variant: "primary"
        glyph: Theme.icons.check
        text: qsTr("Apply")
        enabled: inspector.contentDirty
        tooltip: qsTr("Apply the text to this clip")
        onClicked: inspector.applyText()
    }
}
