import QtQuick
import Drift

// Transport first, timecode second: on a phone the centre of the strip is the
// easiest place to hit, and the readout only has to stay legible.
Item {
    id: transport

    property bool fullscreen: false
    property bool optionsOpen: false
    property bool playing: false
    property real currentSeconds: 0
    property real durationSeconds: 0
    property var formatTimecode: function(seconds) { return "" }

    signal fullscreenToggleRequested()
    signal optionsToggled()

    height: Theme.androidPreviewTransportHeight
    // Backstop: in a narrow landscape pane the centred transport can extend past
    // both edges, and nothing above this sets clip.
    clip: true

    // Width the full five-button row needs, plus the margins either side of it.
    readonly property real fullTransportWidth:
        5 * Theme.androidIconButtonSize + 4 * Theme.spacingXs + 2 * Theme.spacingMd
    // Same for the three buttons that never fold away.
    readonly property real coreTransportWidth:
        3 * Theme.androidIconButtonSize + 2 * Theme.spacingXs + 2 * Theme.spacingMd
    // The view buttons are pinned right while the transport is centred, so the
    // row has to leave that much clear on *both* sides to stay off them.
    readonly property real viewButtonsClearance:
        2 * (2 * Theme.androidIconButtonSize + Theme.spacingXs + Theme.spacingMd)
    // Fullscreen and the view/playback options exist nowhere else in the phone
    // shell, so they claim their space before the ±1s skips do — a clearance
    // test that ran the other way round hid them on every 360-400px phone.
    readonly property bool showViewButtons:
        width >= coreTransportWidth + viewButtonsClearance
    // The ±1s skips are the first thing to go: stepping and play/pause cannot be
    // reached any other way, and jumping has the timeline scrubber as a fallback.
    readonly property bool showSkips:
        width >= fullTransportWidth + (showViewButtons ? viewButtonsClearance : 0)

    Row {
        id: transportRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.rewind
            variant: "text"
            visible: transport.showSkips
            width: visible ? buttonSize : 0
            tooltip: qsTr("Back 1 second")
            onClicked: EditorState.jumpSeconds(-1)
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.stepBack
            variant: "text"
            tooltip: qsTr("Previous frame")
            onClicked: EditorState.stepFrames(-1)
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeLg
            glyph: transport.playing ? Theme.icons.pause : Theme.icons.play
            variant: "text"
            tooltip: transport.playing ? qsTr("Pause") : qsTr("Play")
            onClicked: EditorState.togglePlayback()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.stepForward
            variant: "text"
            tooltip: qsTr("Next frame")
            onClicked: EditorState.stepFrames(1)
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.repeat
            variant: "text"
            tooltip: EditorState.loopWorkAreaEnabled
                     ? qsTr("Loop work area on — tap to turn off")
                     : qsTr("Loop work area off — tap to turn on")
            active: EditorState.loopWorkAreaEnabled
            enabled: EditorState.workAreaActive
            onClicked: EditorState.toggleLoopWorkArea()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.fastForward
            variant: "text"
            visible: transport.showSkips
            width: visible ? buttonSize : 0
            tooltip: qsTr("Forward 1 second")
            onClicked: EditorState.jumpSeconds(1)
        }
    }

    Text {
        id: timecodeLabel
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMd
        anchors.right: transportRow.left
        anchors.rightMargin: Theme.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        // The transport is centred and the view buttons are pinned right, so on
        // a narrow phone this is the strip's smallest column. Drop the total
        // rather than elide the current time, which is the half worth reading —
        // and drop the readout entirely once the column would go negative.
        readonly property string full: transport.formatTimecode(transport.currentSeconds)
                                       + " / " + transport.formatTimecode(transport.durationSeconds)
        readonly property string shortText: transport.formatTimecode(transport.currentSeconds)
        visible: width > 0
        text: width >= fullMetrics.width ? full : shortText
        color: Theme.mutedForeground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeTick
        elide: Text.ElideRight

        TextMetrics {
            id: fullMetrics
            font: timecodeLabel.font
            text: timecodeLabel.full
        }
    }

    Row {
        id: viewButtons
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacingMd
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingXs
        visible: transport.showViewButtons

        IconButton {
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: Theme.icons.sliders
            variant: "text"
            active: transport.optionsOpen
            tooltip: qsTr("View and playback settings")
            onClicked: transport.optionsToggled()
        }

        IconButton {
            buttonSize: Theme.androidIconButtonSize
            iconSize: Theme.iconSizeBase
            glyph: transport.fullscreen ? Theme.icons.minimize : Theme.icons.maximize
            variant: "text"
            active: transport.fullscreen
            tooltip: transport.fullscreen ? qsTr("Exit fullscreen preview")
                                         : qsTr("Fullscreen preview")
            // The panes that hide around the preview belong to AndroidEditor,
            // so the toggle is requested rather than performed here.
            onClicked: transport.fullscreenToggleRequested()
        }
    }
}
