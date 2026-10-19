import QtQuick
import QtQuick.Controls.Basic
import Drift

// Asked once per import that contains numbered images. The footer is custom because there are
// three outcomes, and Escape or a click outside must still answer "cancel" so the caller's
// pending state (a timeline drop, say) is released.
ThemedDialog {
    id: root

    property var found: []
    property var _done: null

    readonly property var rates: [12, 15, 23.976, 24, 25, 29.97, 30, 48, 50, 59.94, 60]
    readonly property real fps: rates[rateBox.currentIndex]
    readonly property int skipped: {
        let n = 0
        for (let i = 0; i < found.length; ++i)
            n += found[i].skippedAfterGap
        return n
    }

    title: qsTr("%n image sequence(s) detected", "", found.length)
    preferredWidth: 440
    showFooter: false
    showAccept: false
    showReject: false
    acceptOnReturn: false

    function ask(sequences, done) {
        root.found = sequences
        root._done = done
        const projectFps = EditorState.projectFile.projectFps()
        let best = 3
        for (let i = 0; i < rates.length; ++i) {
            if (Math.abs(rates[i] - projectFps) < 0.05) {
                best = i
                break
            }
        }
        rateBox.currentIndex = best
        root.open()
    }

    function answer(choice) {
        const done = root._done
        root._done = null
        root.close()
        if (done)
            done(choice, root.fps)
    }

    onClosed: root.answer("cancel")

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: root.visible
        onActivated: root.answer("sequence")
    }

    contentItem: Column {
        spacing: Theme.spacingLg
        width: parent ? parent.width : 408

        Repeater {
            model: root.found

            ThemedLabel {
                required property var modelData
                width: parent.width
                size: "sm"
                elide: Text.ElideMiddle
                text: qsTr("%1  ·  %n frame(s)", "", modelData.frameCount).arg(modelData.displayName)
            }
        }

        Row {
            spacing: Theme.spacingLg

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                size: "sm"
                text: qsTr("Frame rate")
            }

            ThemedComboBox {
                id: rateBox
                width: 100
                model: root.rates.map(function (r) { return String(r) })
            }

            ThemedLabel {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.found.length === 1
                size: "sm"
                text: qsTr("= %1 s").arg((root.found.length === 1 ? root.found[0].frameCount / root.fps : 0).toFixed(1))
            }
        }

        ThemedLabel {
            width: parent.width
            visible: root.skipped > 0
            size: "xs"
            wrapMode: Text.WordWrap
            text: qsTr("%n selected frame(s) after a gap in the numbering will be skipped.", "", root.skipped)
        }

        Row {
            anchors.right: parent.right
            spacing: Theme.spacingLg

            ThemedButton {
                text: qsTr("Cancel")
                variant: "secondary"
                onClicked: root.answer("cancel")
            }

            ThemedButton {
                text: qsTr("Import as stills")
                variant: "secondary"
                onClicked: root.answer("stills")
            }

            ThemedButton {
                text: qsTr("Import as sequence")
                variant: "primary"
                onClicked: root.answer("sequence")
            }
        }
    }
}
