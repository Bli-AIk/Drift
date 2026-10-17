import QtQuick
import Drift

// Shown at startup in place of a fresh empty project whenever "Reopen last project
// on startup" is off: what you were working on, and how to start something. The
// mobile equivalent is AndroidProjectsPage; this mirrors its structure (new project,
// open project, recent projects) with desktop-sized controls and ProjectRow's
// styling (RecentProjectsPopup) for the recents list.
Rectangle {
    id: root

    signal newProjectRequested()
    signal openProjectRequested()
    signal openRecentRequested(string path)

    color: Theme.appBackground

    readonly property var items: EditorState.projectFile.recentProjects


    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, column.implicitHeight + Theme.spacing3xl * 2)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: column
            width: Math.min(560, flick.width - Theme.spacing3xl * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(Theme.spacing3xl, (flick.height - implicitHeight) / 2)
            spacing: Theme.spacing3xl

            StartScreenTitle {
                width: parent.width
            }

            StartScreenActions {
                width: parent.width
                onNewProjectRequested: root.newProjectRequested()
                onOpenProjectRequested: root.openProjectRequested()
            }

            StartScreenRecents {
                width: parent.width
                items: root.items
                onOpenRecentRequested: (path) => root.openRecentRequested(path)
            }
        }
    }
}
