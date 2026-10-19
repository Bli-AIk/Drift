import QtQuick
import Drift

// Shown in the timeline switcher when the project has no composite clips.
ThemedMenuItem {
    enabled: false
    text: qsTr("No composite clips yet")
    icon.name: Theme.icons.info
}
