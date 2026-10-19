import QtQuick
import Drift

Row {
    property var row
    property int effectIndex: -1
    visible: row.paramData.type === "file"
    width: parent.width
    spacing: 8
    Text {
        width: parent.width - 148
        elide: Text.ElideMiddle
        text: {
            const p = row.paramData.value || ""
            if (!p)
                return row.paramData.label + qsTr(": (none)")
            const parts = String(p).split(/[/\\]/)
            return parts[parts.length - 1] || p
        }
        color: row.paramData.missing ? Theme.c.effectsFileParam.destructive
                                         : Theme.c.effectsFileParam.foregroundMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        anchors.verticalCenter: parent.verticalCenter
    }
    IconButton {
        glyph: Theme.icons.folder
        variant: "ghost"
        buttonSize: 22
        iconSize: 12
        tooltip: qsTr("Choose file")
        anchors.verticalCenter: parent.verticalCenter
        onClicked: {
            const filters = row.paramData.fileFilters || ["All files (*)"]
            const url = FileDialogs.openFile(
                qsTr("Choose %1").arg(row.paramData.label), filters)
            if (!url || url.toString() === "")
                return
            EditorState.setEffectStringParam(
                EditorState.selectedTrack, EditorState.selectedClip,
                effectIndex, row.paramData.key, url)
        }
    }
    IconButton {
        glyph: Theme.icons.x
        variant: "ghost"
        buttonSize: 22
        iconSize: 12
        tooltip: qsTr("Clear")
        enabled: !!(row.paramData.value)
        anchors.verticalCenter: parent.verticalCenter
        onClicked: EditorState.setEffectStringParam(
                       EditorState.selectedTrack, EditorState.selectedClip,
                       effectIndex, row.paramData.key, "")
    }
}
