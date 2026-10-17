import QtQuick
import Drift

SettingsSectionCard {
    title: qsTr("App")

    ThemedSwitch {
        checked: EditorState.preferences.reopenLastProject
        text: qsTr("Reopen last project on startup")
        tooltip: qsTr("Automatically restore the last open project on startup. Closing still asks you to save; a crash snapshot never overwrites your save file.")
        onToggled: EditorState.preferences.reopenLastProject = checked
    }

    Column {
        width: parent.width
        spacing: Theme.spacingLg
        visible: Updates.supported

        Rectangle {
            width: parent.width
            height: Theme.borderWidth
            color: Theme.panelBorder
        }

        ThemedLabel {
            text: qsTr("Updates")
        }

        ThemedSwitch {
            checked: Updates.enabled
            text: qsTr("Check on startup")
            tooltip: qsTr("Once a day, check whether a newer Drift has been released")
            onToggled: Updates.enabled = checked
        }

        Row {
            width: parent.width
            spacing: Theme.spacingMd

            ThemedButton {
                id: checkNowButton
                variant: "secondary"
                glyph: Theme.icons.refresh
                text: Updates.checking ? qsTr("Checking…")
                      : Updates.downloading ? qsTr("Downloading…")
                      : qsTr("Check now")
                enabled: !Updates.checking && !Updates.downloading && !Updates.preparing
                onClicked: Updates.checkNow()
            }

            ThemedLabel {
                width: Math.max(0, parent.width - checkNowButton.width - parent.spacing)
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.status.length > 0
                      ? Updates.status
                      : qsTr("Drift %1").arg(Updates.currentVersion)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Theme.borderWidth
        color: Theme.panelBorder
    }

    ThemedLabel {
        text: qsTr("Extra packs")
    }

    ThemedSwitch {
        checked: Addons.remindEssential
        text: qsTr("Remind about essential packs")
        tooltip: qsTr("Pulse the Extras icon when the video, transitions, and audio packs are not installed")
        onToggled: Addons.remindEssential = checked
    }

    ThemedSwitch {
        checked: Addons.remindUpdates
        text: qsTr("Remind about pack updates")
        tooltip: qsTr("Pulse the Extras icon when updates are available for packs you already have installed")
        onToggled: Addons.remindUpdates = checked
    }

    Rectangle {
        width: parent.width
        height: Theme.borderWidth
        color: Theme.panelBorder
    }

    ThemedLabel {
        text: qsTr("Agent access")
    }

    // Shared with the header's AgentAccessDialog rather than restated: the
    // cut-down copy that lived here offered only the Claude command, so a
    // switch turned on from this pane could not be connected from Cursor.
    AgentAccessControls {
        width: parent.width
        showIntro: false
    }
}
