import QtQuick
import Drift
import "SourceLabTime.js" as Time

// One row of the ranges list: a range (rating, name, in-out, duration, note) or a marker
// (tick, name, time). The panel owns selection, editing and the note drawer.
Rectangle {
    id: root

    required property var entry
    property real fps: 30
    property bool useTimecode: true
    property bool selected: false
    property bool editing: false
    property bool noteOpen: false

    readonly property bool isMarker: root.entry.type === "marker"
    readonly property int rating: root.entry.rating ?? 0
    readonly property color ratingColor: root.rating > 0 ? Theme.c.sourceLabPanel.ratingFavorite
                                         : root.rating < 0 ? Theme.c.sourceLabPanel.ratingReject
                                                           : Theme.c.sourceLabPanel.ratingNeutral

    signal pressed(int modifiers)
    signal activated()
    signal renameRequested()
    signal contextRequested()
    signal renameCommitted(string name)
    signal editCancelled()
    signal noteToggled()
    signal noteCommitted(string note)
    
    function clock(seconds) {
        return root.useTimecode ? Time.format(seconds, root.fps) : Time.formatClock(seconds, 2)
    }

    height: rowLine.height + (noteField.visible ? noteField.height + Theme.spacingSm : 0) + Theme.spacingSm * 2
    radius: Theme.c.sourceLabPanel.rowRadius
    color: root.selected ? Theme.c.sourceLabPanel.rowSelected
                         : hover.hovered ? Theme.c.sourceLabPanel.rowHover : "transparent"
    border.width: root.selected ? Theme.c.sourceLabPanel.cardBorderWidth : 0
    border.color: Theme.c.sourceLabPanel.rowSelectedBorder

    onEditingChanged: {
        if (root.editing) {
            nameEdit.text = root.entry.name ?? ""
            nameEdit.forceActiveFocus()
            nameEdit.selectAll()
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: (point, button) => root.pressed(point.modifiers)
        onDoubleTapped: (point, button) => {
            const p = nameBox.mapFromItem(root, point.position.x, point.position.y)
            if (nameBox.contains(p))
                root.renameRequested()
            else
                root.activated()
        }
    }
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.contextRequested()
    }

    Row {
        id: rowLine
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingSm
        spacing: Theme.spacingMd
        height: Theme.controlHeightSm

        IconGlyph {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height
            glyph: root.isMarker ? Theme.icons.bookmark : (root.rating < 0 ? Theme.icons.x : Theme.icons.star)
            iconSize: Theme.iconSizeSm
            iconColor: root.isMarker ? Theme.c.sourceLabPanel.marker : root.ratingColor
        }

        Item {
            id: nameBox
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(40, parent.width - parent.spacing * 3 - parent.height * 2 - timeLabel.implicitWidth)
            height: parent.height

            ThemedLabel {
                anchors.fill: parent
                visible: !root.editing
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                tone: "default"
                size: "sm"
                text: (root.entry.name ?? "").length > 0 ? root.entry.name
                      : (root.isMarker ? qsTr("Marker") : qsTr("Range"))
                opacity: (root.entry.name ?? "").length > 0 ? 1 : 0.6
            }
            ThemedTextField {
                id: nameEdit
                anchors.fill: parent
                visible: root.editing
                topPadding: 0
                bottomPadding: 0
                onAccepted: root.renameCommitted(text)
                Keys.onEscapePressed: root.editCancelled()
                onActiveFocusChanged: if (!activeFocus && root.editing) root.renameCommitted(text)
            }
        }

        ThemedLabel {
            id: timeLabel
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.monoFontFamily
            text: root.isMarker
                  ? root.clock(root.entry.time)
                  : qsTr("%1 - %2  (%3)").arg(root.clock(root.entry.in)).arg(root.clock(root.entry.out))
                    .arg(Time.formatClock(root.entry.out - root.entry.in, 1))
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.isMarker || (root.entry.note ?? "").length > 0 || root.noteOpen
            glyph: Theme.icons.pencil
            iconSize: Theme.iconSizeSm
            buttonSize: parent.height
            active: root.noteOpen || (root.entry.note ?? "").length > 0
            tooltip: qsTr("Note")
            onClicked: root.noteToggled()
        }
    }

    ThemedTextField {
        id: noteField
        anchors.top: rowLine.bottom
        anchors.topMargin: Theme.spacingSm
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingSm + Theme.controlHeightSm
        anchors.rightMargin: Theme.spacingSm
        visible: root.noteOpen
        placeholderText: qsTr("Add a note")
        text: root.entry.note ?? ""
        onEditingFinished: if (text !== (root.entry.note ?? "")) root.noteCommitted(text)
    }
}
