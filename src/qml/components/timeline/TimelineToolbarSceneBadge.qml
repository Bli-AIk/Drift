import QtQuick
import Drift

// Active timeline name, centred between the toolbar groups, with the sequence switcher.
Rectangle {
    id: sceneBadge

    property var host
    property Item leftGroup
    property Item rightGroup

    // Sits between the two button groups, which are anchored to the
    // toolbar edges and grow freely. Prefer dead centre, but slide
    // aside to stay clear of them, and drop out entirely once the
    // gap can no longer fit the badge.
    // leftGroup is stretched up to rightGroup so it can clip, so its buttons
    // end at implicitWidth, not width.
    // Worked out left-to-right and flipped at the end: an explicit x is not
    // mirrored along with the anchors that swap the two groups under RTL.
    readonly property real gapStart: Theme.spacingLg
                                     + Math.min(leftGroup.implicitWidth, leftGroup.width) + 12
    readonly property real gapEnd: parent.width - Theme.spacingLg - rightGroup.width - 12
    readonly property real ltrX: Math.max(gapStart, Math.min((parent.width - width) / 2,
                                                              gapEnd - width))

    x: Qt.application.layoutDirection === Qt.RightToLeft ? parent.width - ltrX - width : ltrX
    anchors.verticalCenter: parent.verticalCenter
    visible: gapEnd - gapStart >= width
    width: sceneRow.implicitWidth + 20
    height: 26
    radius: Theme.c.timelineToolbarSceneBadge.radius
    color: "transparent"
    border.width: Theme.c.timelineToolbarSceneBadge.borderWidth
    border.color: Qt.rgba(Theme.c.timelineToolbarSceneBadge.border.r, Theme.c.timelineToolbarSceneBadge.border.g, Theme.c.timelineToolbarSceneBadge.border.b, 0.1)

    // The active timeline: "Main", or the open composite's name.
    readonly property string activeName: {
        const active = EditorState.activeSequenceId
        if (active === "")
            return qsTr("Main")
        const tabs = EditorState.sequenceTabs
        for (var i = 0; i < tabs.length; i++) {
            if (tabs[i].id === active)
                return tabs[i].name
        }
        return qsTr("Composite")
    }

    Row {
        id: sceneRow
        anchors.centerIn: parent
        spacing: 6

        IconGlyph {
            glyph: EditorState.activeSequenceId === "" ? Theme.icons.film : Theme.icons.layers
            iconSize: 14
            iconColor: Theme.c.timelineToolbarSceneBadge.icon
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: sceneBadge.activeName
            color: Theme.c.timelineToolbarSceneBadge.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 180)
            anchors.verticalCenter: parent.verticalCenter
        }
        IconGlyph {
            glyph: Theme.icons.chevronDown
            iconSize: 12
            iconColor: Theme.c.timelineToolbarSceneBadge.icon
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: sceneMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: sceneMenu.opened ? sceneMenu.close() : sceneMenu.popup(0, sceneBadge.height + 4)
    }

    ThemedToolTip {
        visible: sceneMouse.containsMouse && !sceneMenu.opened
        text: qsTr("Switch between the main timeline and composite clips")
    }

    ThemedContextMenu {
        id: sceneMenu
        implicitWidth: 240

        // Composites come and go with the project's assets, which have no notify of
        // their own here, so the list is read fresh on each open.
        onAboutToShow: sceneBadge.rebuildSceneMenu()
    }

    Component {
        id: sceneItemComponent
        TimelineToolbarSceneMenuItem { }
    }

    Component {
        id: sceneEmptyComponent
        TimelineToolbarSceneEmptyItem { }
    }

    Component {
        id: sceneSeparatorComponent
        ThemedMenuSeparator { }
    }

    function rebuildSceneMenu() {
        while (sceneMenu.count > 0)
            sceneMenu.removeItem(sceneMenu.itemAt(0))
        sceneMenu.addItem(sceneItemComponent.createObject(null,
            { sequenceId: "", sequenceName: qsTr("Main") }))
        sceneMenu.addItem(sceneSeparatorComponent.createObject(null))
        const composites = EditorState.compositeSequences()
        if (composites.length === 0)
            sceneMenu.addItem(sceneEmptyComponent.createObject(null))
        for (var i = 0; i < composites.length; i++) {
            sceneMenu.addItem(sceneItemComponent.createObject(null,
                { sequenceId: composites[i].id, sequenceName: composites[i].name }))
        }
    }
}
