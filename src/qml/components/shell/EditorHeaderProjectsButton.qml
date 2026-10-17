import QtQuick
import Drift

// Gmail-style status pill: saved/unsaved dot, project name, chevron.
Rectangle {
    id: projectsButton
    property string projectName
    signal openFileRequested()
    signal newProjectRequested()
    signal openRecentRequested(string path)
    signal closeProjectRequested()
    signal saveAsRequested()
    signal packageRequested()
    signal saveJsonRequested()
    signal openJsonRequested()
    signal propertiesRequested()

    readonly property bool open: recentPopupLoader.shown
    readonly property bool saved: !EditorState.projectFile.hasUnsavedChanges

    // Cap width so a long name does not shove the right-side actions.
    width: Math.min(projectsRow.implicitWidth + Theme.spacingXl * 2, 260)
    height: 32
    radius: Theme.radiusPill
    color: projectsArea.containsMouse || open ? Theme.popoverHover : Theme.accent
    anchors.verticalCenter: parent.verticalCenter
    clip: true

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Projects")
    Accessible.description: saved ? qsTr("All changes saved")
                                  : qsTr("Unsaved changes")

    Row {
        id: projectsRow
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingMd

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: projectsButton.saved ? Theme.constructive : Theme.destructive
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            // Cap against the pill's max width (dot + gaps + chevron + padding).
            readonly property real maxTextWidth: 260 - Theme.spacingXl * 2
                                                 - 8 - Theme.iconSizeSm
                                                 - Theme.spacingMd * 2
            width: Math.min(implicitWidth, maxTextWidth)
            text: projectsButton.projectName
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        IconGlyph {
            glyph: Theme.icons.chevronDown
            iconSize: Theme.iconSizeSm
            iconColor: Theme.mutedForeground
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    ThemedToolTip {
        visible: projectsArea.containsMouse && !projectsButton.open
        text: projectsButton.saved
              ? qsTr("Projects — click to switch or start new")
              : qsTr("Unsaved changes — click to switch or start new")
    }

    MouseArea {
        id: projectsArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: recentPopupLoader.ensure().open()
    }

    // Fills the button so the popup still hangs off its bottom edge.
    LazyLoader {
        id: recentPopupLoader
        anchors.fill: parent
        sourceComponent: Component {
            RecentProjectsPopup {
                y: parent.height + Theme.spacingMd
                onOpenFileRequested: projectsButton.openFileRequested()
                onNewProjectRequested: projectsButton.newProjectRequested()
                onOpenRecentRequested: (path) => projectsButton.openRecentRequested(path)
                onCloseProjectRequested: projectsButton.closeProjectRequested()
                onSaveAsRequested: projectsButton.saveAsRequested()
                onPackageRequested: projectsButton.packageRequested()
                onSaveJsonRequested: projectsButton.saveJsonRequested()
                onOpenJsonRequested: projectsButton.openJsonRequested()
                // Disabled: external project imports. Uncomment with the open*() functions above.
                // onImportPremiereRequested: root.openPremiereProject()
                // onImportMogrtRequested: root.openMogrt()
                // onImportKdenliveRequested: root.openKdenliveProject()
                // onImportResolveRequested: root.openResolveProject()
                // onImportEdlRequested: root.openEdlTimeline()
                // onImportOtioRequested: root.openOtioTimeline()
                onPropertiesRequested: projectsButton.propertiesRequested()
            }
        }
    }
}
