import QtQuick
import Drift
import "SourceLabTime.js" as Time

// What the chosen action would do: the steps, the length of the result, and whether it re-encodes.
Rectangle {
    id: root

    property var plan: ({})
    property real fps: 30
    property bool useTimecode: true

    readonly property var steps: root.plan.steps ?? []
    readonly property bool streamCopy: root.plan.streamCopy ?? false

    function clock(seconds) {
        return root.useTimecode ? Time.format(seconds, root.fps) : Time.formatClock(seconds, 2)
    }

    implicitHeight: column.height + Theme.spacingLg * 2
    radius: Theme.c.sourceLabPanel.cardRadius
    color: Theme.c.sourceLabPanel.cardBackground
    border.width: Theme.c.sourceLabPanel.cardBorderWidth
    border.color: Theme.c.sourceLabPanel.cardBorder

    Column {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingLg
        spacing: Theme.spacingSm

        ThemedLabel {
            width: parent.width
            tone: "default"
            size: "sm"
            text: root.streamCopy ? qsTr("Copies the streams, no re-encode")
                  : (root.plan.encode ?? false) ? qsTr("Re-encodes the result") : qsTr("No re-encode needed")
        }

        Repeater {
            model: root.steps
            ThemedLabel {
                required property string modelData
                required property int index
                width: column.width
                wrapMode: Text.WordWrap
                text: qsTr("%1. %2").arg(index + 1).arg(modelData)
            }
        }

        ThemedLabel {
            width: parent.width
            font.family: Theme.monoFontFamily
            text: qsTr("Result length: %1").arg(Time.formatClock(root.plan.outputDuration ?? 0, 1))
        }

        ThemedLabel {
            width: parent.width
            visible: root.streamCopy
            wrapMode: Text.WordWrap
            font.family: Theme.monoFontFamily
            text: qsTr("Starts at the previous keyframe, %1").arg(root.clock(root.plan.snappedIn ?? 0))
        }

        ThemedLabel {
            width: parent.width
            visible: (root.plan.error ?? "").length > 0
            wrapMode: Text.WordWrap
            color: Theme.c.sourceLabPanel.error
            text: root.plan.error ?? ""
        }
    }
}
