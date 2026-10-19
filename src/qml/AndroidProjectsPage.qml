import QtQuick
import QtQuick.Controls.Basic
import Drift
// The home screen's start destination: what you were working on, and how to start something.
//
// The layout picker used to sit here, above the recents and above the buttons, so the first
// thing a returning user saw was a form asking about aspect ratios. It is gone: "New project"
// opens the picker directly and the canvas is inferred from the first clip, which is what every
// phone editor does and what the desktop's own "Decide later" path already allowed.
Item {
    id: root

    signal newProjectRequested()
    signal quickEditRequested()
    signal openProjectRequested()
    signal openRecentRequested(string path)

    // Quick edit leads: same first two taps as New project, minus the canvas question,
    // so the shortest path is also the prominent one. New project keeps its own tile for
    // the edit that starts empty rather than from a clip.
    readonly property var tiles: [
        { id: "quick", label: qsTr("Quick edit"), detail: qsTr("Pick a clip, start now"),
          icon: Theme.icons.sparkles, primary: true },
        { id: "new", label: qsTr("New project"), detail: qsTr("Choose a canvas, start empty"),
          icon: Theme.icons.plus, primary: false }
    ]

    function triggerTile(tileId) {
        if (tileId === "quick")
            root.quickEditRequested()
        else if (tileId === "new")
            root.newProjectRequested()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.topMargin: root.SafeArea.margins.top
        anchors.leftMargin: root.SafeArea.margins.left
        anchors.rightMargin: root.SafeArea.margins.right
        contentWidth: width
        contentHeight: pageColumn.implicitHeight + Theme.spacing2xl
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: pageColumn
            width: parent.width
            spacing: Theme.spacing2xl
            topPadding: Theme.spacing2xl
            leftPadding: Theme.androidPagePadding
            rightPadding: Theme.androidPagePadding

            readonly property real contentWidth: width - leftPadding - rightPadding

            AndroidHomeWordmark {
                width: pageColumn.contentWidth
            }

            // --- Start something ----------------------------------------------
            Column {
                width: pageColumn.contentWidth
                spacing: Theme.androidTouchGap

                Repeater {
                    model: root.tiles

                    delegate: AndroidHomeStartTile {
                        width: pageColumn.contentWidth
                        onTriggered: (tileId) => root.triggerTile(tileId)
                    }
                }
            }

            // --- Recent projects ----------------------------------------------
            //
            // A wrapping grid rather than the single horizontal strip this used to be. The strip
            // showed two and a half cards and hid the rest behind a sideways flick with nothing
            // saying so, which on the one screen whose whole job is "get back to your work" is
            // the wrong trade. Opening a project from disk is the rarer case, so it loses its
            // full-width tile and becomes the button beside this heading.
            Column {
                width: pageColumn.contentWidth
                spacing: Theme.spacingMd

                Item {
                    width: parent.width
                    height: Math.max(recentsLabel.implicitHeight, openButton.height)

                    ThemedLabel {
                        id: recentsLabel
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Recent projects")
                        tone: "default"
                        size: "sm"
                    }

                    ThemedButton {
                        id: openButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        variant: "secondary"
                        glyph: Theme.icons.folder
                        text: qsTr("Open")
                        tooltip: qsTr("Open a project from this device")
                        onClicked: {
                            Haptics.select()
                            root.openProjectRequested()
                        }
                    }
                }

                ThemedLabel {
                    width: parent.width
                    visible: EditorState.projectFile.recentProjects.length === 0
                    wrapMode: Text.WordWrap
                    text: qsTr("Nothing here yet — projects you save will show up in this list.")
                }

                Grid {
                    id: recentGrid
                    width: parent.width
                    columns: Math.max(2, Math.floor(width / 220))
                    spacing: Theme.spacingMd
                    visible: EditorState.projectFile.recentProjects.length > 0

                    readonly property real cellWidth:
                        (width - spacing * (columns - 1)) / columns

                    Repeater {
                        model: EditorState.projectFile.recentProjects

                        delegate: AndroidHomeRecentCard {
                            width: recentGrid.cellWidth
                            onOpenRequested: (path) => root.openRecentRequested(path)
                        }
                    }
                }
            }
        }
    }
}
