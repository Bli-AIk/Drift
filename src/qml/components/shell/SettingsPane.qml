import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift

// Every editor and app preference, in one scrolling pane: the editor, then the app.
// Hosted by SettingsDialog; it used to be a tab in the assets panel's rail.
//
// Canvas size, aspect and frame rate are not here. On the phone they belong to the
// project rather than to preferences, and the project title's sheet already offers
// them under Canvas & layout and Project properties; on desktop they are the
// header's Video dialog. Both reach VideoSizeControls directly.
Item {
    id: root

    // Natural height of the whole list, so the dialog can size itself to the content
    // and cap it at what fits on screen instead of guessing.
    readonly property real contentHeight: flick.contentHeight

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: settingsColumn.height + Theme.spacing3xl
        clip: true
        property int dragLocks: 0
        interactive: dragLocks === 0
        ScrollBar.vertical: AppScrollBar { }

        Column {
            id: settingsColumn
            x: Theme.pagePadding
            width: parent.width - Theme.pagePadding * 2
            spacing: Theme.spacingXl
            topPadding: Theme.pagePadding
            bottomPadding: Theme.spacingXl


            SettingsPreviewSection { }

            SettingsPlaybackSection { }

            SettingsInterfaceSection { }

            SettingsAppSection { }

            // Voice and transcription services the user brings their own account for. Nothing is
            // sent to either until the key is set and the matching switch is on.
            SettingsCloudProvidersSection { }

            SettingsMarketplaceSection { }
        }
    }
}
