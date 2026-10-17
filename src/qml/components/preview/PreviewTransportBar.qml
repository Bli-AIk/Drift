import QtQuick
import QtQuick.Layouts
import Drift

// The strip under the preview that is always there: timecode, transport and fullscreen. Everything
// else lives in the preview's OSD. A RowLayout keeps Play centred while the side groups compress
// instead of colliding at narrow widths.
Item {
    id: bar

    property int projectFps: 30
    property real currentSeconds: 0
    property real durationSeconds: 0
    property bool fullscreen: false
    // Formats seconds as the panel's timecode.
    property var formatTimecode: function (seconds) { return "" }
    signal fullscreenRequested()

    function withShortcut(label, actionId) {
        const key = EditorState.shortcutFor(actionId)
        return key.length > 0 ? qsTr("%1 (%2)").arg(label).arg(key) : label
    }

    implicitHeight: Theme.iconButtonSize + Theme.previewTransportPadding * 2

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacing2xl + Theme.spacingSm
        anchors.rightMargin: Theme.spacing2xl + Theme.spacingSm
        spacing: Theme.spacingLg

        PreviewTransportTimecode {
            projectFps: bar.projectFps
            currentSeconds: bar.currentSeconds
            durationSeconds: bar.durationSeconds
            formatTimecode: bar.formatTimecode
        }

        // Spacers on both sides keep Play optically centred while still letting the whole row
        // shrink instead of overlap.
        Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }

        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingXs

            PreviewTransportRewindButton { }
            PreviewTransportStepBackButton {
                shortcutTip: bar.withShortcut(qsTr("Previous frame"), "stepBack")
            }
            PreviewTransportPlayButton { }
            PreviewTransportStepForwardButton {
                shortcutTip: bar.withShortcut(qsTr("Next frame"), "stepForward")
            }
            PreviewTransportLoopButton { }
            PreviewTransportFastForwardButton { }
        }

        Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }

        PreviewTransportFullscreenButton {
            fullscreen: bar.fullscreen
            onFullscreenRequested: bar.fullscreenRequested()
        }
    }
}
