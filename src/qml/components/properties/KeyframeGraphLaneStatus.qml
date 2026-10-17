import QtQuick
import Drift

Text {
    property var host
    width: parent.width
    wrapMode: Text.WordWrap
    text: {
        const keys = host.keyCount === 0 ? qsTr("No keyframes")
                                         : qsTr("%n keyframes", "", host.keyCount)
        let hint = ""
        if (!host.curveEditing && host.keyCount > 0)
            hint = " · " + qsTr("Expand for handles")
        if (!EditorState.beatGridVisible || !host.analyzed)
            return keys + hint
        // The detector publishes no bpm when the tempo estimate was not
        // confident — say so, rather than leaving the grid button lit over
        // an empty lane. Onsets may still be perfectly usable.
        return (host.bpm > 0 ? keys + " · " + Math.round(host.bpm) + qsTr(" BPM")
                             : keys + qsTr(" · no beat found")) + hint
    }
    color: (!host.curveEditing && host.keyCount > 0) ? Theme.c.keyframeGraphLaneStatus.foregroundAccent : Theme.c.keyframeGraphLaneStatus.foregroundMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSizeXs

    MouseArea {
        anchors.fill: parent
        enabled: !host.curveEditing && host.keyCount > 0
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: host.toggleExpanded()
    }
}
