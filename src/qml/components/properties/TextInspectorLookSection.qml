import QtQuick
import Drift

CollapsibleSection {
    id: root
    property var inspector
    property alias boxPaddingField: decorations.boxPaddingField
    property alias boxRadiusField: decorations.boxRadiusField
    property alias wordHighlightPaddingField: decorations.wordHighlightPaddingField
    property alias wordHighlightRadiusField: decorations.wordHighlightRadiusField
    property alias underlineWidthField: decorations.underlineWidthField
    property alias underlineOffsetField: decorations.underlineOffsetField
    width: parent.width
    title: qsTr("Effect")
    tooltip: qsTr("Shadow, outline, neon and friends — a recipe that builds the layers below")
    collapsible: false
    visible: inspector.hasTextStyle

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: qsTr("Shadow, outline, neon… built as layers you can fine-tune below.")
        color: Theme.c.textInspectorLookSection.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    TextLookPicker {
        width: parent.width
        lookId: inspector.textStyle.lookId || ""
        sampleText: inspector.lookSampleText
        fontFamily: inspector.textStyle.fontFamily || ""
        fontWeight: Math.round(Number(inspector.textStyle.fontWeight) || 400)
        italic: inspector.textStyle.italic === true
        onLookPicked: id => EditorState.applyTextLook(EditorState.selectedTrack,
                                                      EditorState.selectedClip, id)
    }

    TextParamSlots {
        width: parent.width
        visible: !!inspector.selectedLook && (inspector.selectedLook.params || []).length > 0
        specs: inspector.selectedLook ? (inspector.selectedLook.params || []) : []
        values: inspector.textStyle.lookParams || ({})
        onChanged: (id, value) => EditorState.setTextLookParam(
                       EditorState.selectedTrack, EditorState.selectedClip, id, value)
        onPreviewChanged: (id, value) => EditorState.previewSetTextLookParam(
                              EditorState.selectedTrack, EditorState.selectedClip, id, value)
        onDragStarted: EditorState.beginPreviewDrag(qsTr("Adjust text look"))
        onDragEnded: EditorState.commitPreviewDrag()
    }

    Row {
        width: parent.width
        spacing: Theme.spacingSm

        Text {
            width: parent.width - addLayerButton.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Layers")
            color: Theme.c.textInspectorLookSection.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.DemiBold
        }
        ThemedButton {
            id: addLayerButton
            variant: "secondary"
            glyph: Theme.icons.plus
            text: qsTr("Add layer")
            tooltip: qsTr("Add a fill, stroke, shadow, glow or extrude layer")
            onClicked: addLayerMenu.popup()

            ThemedContextMenu {
                id: addLayerMenu
                ThemedMenuItem { text: qsTr("Fill"); onTriggered: inspector.addLayer("fill") }
                ThemedMenuItem { text: qsTr("Stroke"); onTriggered: inspector.addLayer("stroke") }
                ThemedMenuItem { text: qsTr("Shadow"); onTriggered: inspector.addLayer("shadow") }
                ThemedMenuItem { text: qsTr("Glow"); onTriggered: inspector.addLayer("glow") }
                ThemedMenuItem { text: qsTr("Extrude"); onTriggered: inspector.addLayer("extrude") }
            }
        }
    }

    Text {
        visible: inspector.layers.length === 0
        width: parent.width
        wrapMode: Text.WordWrap
        text: qsTr("No layers. Pick an effect above or add a fill to start.")
        color: Theme.c.textInspectorLookSection.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    // Integer model so rows survive the fresh QVariantList every edit produces; the list
    // is walked from the back so the front-most layer sits on top.
    Repeater {
        model: inspector.layers.length
        delegate: ShadingLayerRow {
            required property int index
            width: parent.width
            layerData: inspector.layers[inspector.layers.length - 1 - index] || ({})
            styleData: inspector.textStyle
            position: index
            count: inspector.layers.length
            expanded: inspector.expandedLayerIds[layerId] === true
            onToggleRequested: inspector.setLayerExpanded(layerId, !expanded)
        }
    }
    TextInspectorDecorations {
        id: decorations
        width: parent.width
        inspector: root.inspector
    }
}
