import QtQuick
import Drift

Column {
    property var editor
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: 12
    spacing: 4

    // Saves the selected caption clip as .srt, .vtt or .ass. The suffix is what
    // AppController::exportSubtitleFile keys off to pick a writer, and on Android
    // it is also what FileDialogs maps to a MIME type for the storage provider —
    // passing the wrong suffix there writes ASS bytes into a file named .srt.
    function exportAs(suffix) {
        var filters = []
        if (suffix === "ass")
            filters.push(qsTr("Advanced SubStation Alpha (*.ass)"))
        else if (suffix === "vtt")
            filters.push(qsTr("WebVTT subtitles (*.vtt)"))
        else
            filters.push(qsTr("SubRip subtitles (*.srt)"))

        const url = FileDialogs.saveFile(
            qsTr("Export Subtitles"), filters,
            (editor.clip && editor.clip.name) ? editor.clip.name : EditorState.projectFile.projectName,
            suffix)
        if (url != "")
            EditorState.subtitles.exportFile(
                editor.trackIndex, editor.clipIndex, url, timelineTimesBox.checked)
    }

    Item {
        width: parent.width
        height: titleText.implicitHeight

        Text {
            id: titleText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Subtitles")
            color: Theme.c.subtitleEditorHeader.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 captions").arg(editor.cues.length)
            color: Theme.c.subtitleEditorHeader.foregroundMuted
            font.family: Theme.monoFontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }

    Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: editor.compactEdit
              ? qsTr("Play the timeline — the line on screen lights up. Tap any line to edit it.")
              : qsTr("Play the timeline — the line on screen lights up. Click any line to jump to it and edit it below.")
        color: Theme.c.subtitleEditorHeader.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        opacity: 0.8
    }

    Row {
        width: parent.width
        spacing: 6

        ThemedButton {
            width: (parent.width - parent.spacing) / 2
            text: qsTr("Import")
            variant: "secondary"
            glyph: Theme.icons.upload
            tooltip: qsTr("Replace these captions from a .srt or .vtt file")
            onClicked: {
                const url = FileDialogs.openFile(
                    qsTr("Import Subtitles"),
                    [qsTr("Subtitles (*.srt *.vtt)"), qsTr("All files (*)")])
                if (url != "")
                    EditorState.subtitles.importFile(
                        editor.trackIndex, editor.clipIndex, url)
            }
        }

        ThemedButton {
            width: (parent.width - parent.spacing) / 2
            text: qsTr("Export")
            variant: "secondary"
            glyph: Theme.icons.save
            tooltip: qsTr("Save captions as a .srt, .vtt or .ass file")
            enabled: editor.cues.length > 0
            onClicked: exportMenu.popup()
        }

        ThemedContextMenu {
            id: exportMenu

            ThemedMenuItem {
                text: qsTr("SubRip subtitles (.srt)")
                onTriggered: header.exportAs("srt")
            }
            ThemedMenuItem {
                text: qsTr("WebVTT subtitles (.vtt)")
                onTriggered: header.exportAs("vtt")
            }
            ThemedMenuItem {
                text: qsTr("Advanced SubStation Alpha (.ass)")
                onTriggered: header.exportAs("ass")
            }
        }
    }

    ThemedCheckBox {
        id: timelineTimesBox
        width: parent.width
        text: qsTr("Timestamps from the start of the video")
        tooltip: qsTr("Offset the exported captions by this clip's start so they match the exported video")
    }
}
