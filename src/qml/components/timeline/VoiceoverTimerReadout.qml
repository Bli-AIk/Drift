import QtQuick
import Drift

// Live take length, m:ss.t.
Text {
    text: {
        const secs = EditorState.audioRecordSeconds;
        const m = Math.floor(secs / 60);
        const s = Math.floor(secs % 60);
        const ms = Math.floor((secs % 1) * 10);
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s) + "." + ms;
    }
    font.family: Theme.monoFontFamily
    font.bold: true
    font.pixelSize: 11
    color: Theme.panelForeground
    anchors.verticalCenter: parent.verticalCenter
}
