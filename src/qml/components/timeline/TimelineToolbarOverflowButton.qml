import QtQuick
import Drift

// More-actions button. Rebuilds its menu from the toolbar layout each time it opens.
TimelineToolbarToolButton {
    id: overflowButton

    property var host
    signal customizeRequested()

    glyph: Theme.icons.ellipsis
    tooltip: qsTr("More edit actions")
    active: overflowMenu.opened
    onClicked: overflowMenu.opened ? overflowMenu.close()
                                   : overflowMenu.popup(0, overflowButton.height)

    function rebuildOverflowMenu() {
        // Everything before the fixed "Customize" tail is generated.
        while (overflowMenu.count > 2)
            overflowMenu.removeItem(overflowMenu.itemAt(0))
        const list = host.layout.menu
        const always = () => true
        var at = 0
        for (var i = 0; i < list.length; i++) {
            if (list[i] === "separator") {
                if (host.separatorNeeded(list, i, always))
                    overflowMenu.insertItem(at++, overflowSeparatorComponent.createObject(null))
                continue
            }
            overflowMenu.insertItem(at++, overflowItemComponent.createObject(null,
                                                                            { actionId: list[i], host: host }))
        }
        customizeSeparator.visible = at > 0
    }

    Component {
        id: overflowItemComponent
        TimelineToolbarOverflowMenuItem { }
    }

    Component {
        id: overflowSeparatorComponent
        ThemedMenuSeparator { }
    }

    ThemedContextMenu {
        id: overflowMenu
        implicitWidth: 260

        // Rebuilt on each open from the current layout. A Menu cannot host a
        // Repeater, and Instantiator cannot mix items with separators.
        onAboutToShow: overflowButton.rebuildOverflowMenu()

        ThemedMenuSeparator { id: customizeSeparator }
        ThemedMenuItem {
            text: qsTr("Customize toolbar…")
            icon.name: Theme.icons.sliders
            onTriggered: overflowButton.customizeRequested()
        }
    }
}
