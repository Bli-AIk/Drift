pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import Drift

Item {
    id: row

    required property var panel
    required property int index
    required property int cueIndex
    required property real start
    required property real end
    required property string text
    required property bool overlapsNext

    readonly property bool selected: !!panel.selectedMap[cueIndex]
    readonly property bool active: cueIndex === panel.activeCue
    readonly property bool editingText: panel.editIndex === cueIndex && panel.editColumn === "text"
    readonly property bool editingStart: panel.editIndex === cueIndex && panel.editColumn === "start"
    readonly property bool editingEnd: panel.editIndex === cueIndex && panel.editColumn === "end"

    property real textEditorHeight: 0

    onEditingTextChanged: {
        if (!editingText)
            textEditorHeight = 0
    }

    width: ListView.view ? ListView.view.width : 0
    height: editingText ? Math.min(160, Math.max(panel.rowHeight, textEditorHeight + 4))
                        : panel.rowHeight

    component Cell: Text {
        height: row.panel.rowHeight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: Theme.c.subtitleCueGrid.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeSm
    }

    component TimeEditor: TextField {
        id: field

        required property string column
        required property real value

        height: row.panel.rowHeight
        padding: 0
        leftPadding: Theme.spacingMd
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.c.subtitleCueGrid.foreground
        selectionColor: Theme.c.subtitleCueGrid.selectedMarker
        selectedTextColor: Theme.c.subtitleCueGrid.foreground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeSm
        selectByMouse: true
        text: row.panel.formatTime(value)
        background: Rectangle {
            color: Theme.c.subtitleCueGrid.background
            border.width: Theme.c.subtitleCueGrid.borderWidthFocus
            border.color: Theme.c.subtitleCueGrid.borderFocus
        }
        Component.onCompleted: {
            forceActiveFocus()
            selectAll()
        }
        onAccepted: row.panel.commitTime(row.cueIndex, column, text)
        Keys.onEscapePressed: row.panel.cancelEdit()
        onActiveFocusChanged: {
            if (!activeFocus && row.panel.editIndex === row.cueIndex && row.panel.editColumn === column)
                row.panel.commitTime(row.cueIndex, column, text)
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.c.subtitleCueGrid.rowAlt
        opacity: row.index % 2 === 1 ? Theme.c.subtitleCueGrid.opacityRowAlt : 0
    }

    Rectangle {
        anchors.fill: parent
        visible: row.active
        color: Theme.c.subtitleCueGrid.rowActive
        opacity: Theme.c.subtitleCueGrid.opacityRowActive
    }

    Rectangle {
        anchors.fill: parent
        visible: row.selected
        color: Theme.c.subtitleCueGrid.rowSelected
        opacity: Theme.c.subtitleCueGrid.opacityRowSelected
    }

    Rectangle {
        visible: row.selected || row.active
        width: Theme.c.subtitleCueGrid.markerWidth
        height: parent.height
        color: row.selected ? Theme.c.subtitleCueGrid.selectedMarker : Theme.c.subtitleCueGrid.activeMarker
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: (mouse) => {
            row.panel.forceActiveFocus()
            row.panel.clickCue(row.cueIndex, mouse.modifiers)
        }
        onDoubleClicked: (mouse) => row.panel.beginEditAt(row.cueIndex, mouse.x)
    }

    Row {
        id: cells
        height: row.panel.rowHeight
        leftPadding: Theme.c.subtitleCueGrid.markerWidth

        Cell {
            width: row.panel.colNumberWidth
            rightPadding: Theme.spacingMd
            horizontalAlignment: Text.AlignRight
            color: Theme.c.subtitleCueGrid.foregroundMuted
            text: row.cueIndex + 1
        }

        Item {
            width: row.panel.colTimeWidth
            height: row.panel.rowHeight

            Cell {
                anchors.fill: parent
                visible: !row.editingStart
                leftPadding: Theme.spacingMd
                text: row.panel.formatTime(row.start)
            }
            Loader {
                anchors.fill: parent
                active: row.editingStart
                sourceComponent: TimeEditor {
                    column: "start"
                    value: row.start
                }
            }
        }

        Item {
            width: row.panel.colTimeWidth
            height: row.panel.rowHeight

            Cell {
                anchors.fill: parent
                visible: !row.editingEnd
                leftPadding: Theme.spacingMd
                color: row.overlapsNext ? Theme.c.subtitleCueGrid.foregroundOverlap : Theme.c.subtitleCueGrid.foreground
                text: row.panel.formatTime(row.end)
            }
            Loader {
                anchors.fill: parent
                active: row.editingEnd
                sourceComponent: TimeEditor {
                    column: "end"
                    value: row.end
                }
            }
        }

        Cell {
            width: row.panel.colDurationWidth
            leftPadding: Theme.spacingMd
            color: Theme.c.subtitleCueGrid.foregroundMuted
            text: Math.max(0, row.end - row.start).toFixed(3)
        }

        Item {
            width: row.width - row.panel.fixedColumnsWidth
            height: parent.height

            Cell {
                anchors.fill: parent
                visible: !row.editingText
                leftPadding: Theme.spacingMd
                rightPadding: Theme.spacingMd
                font.family: Theme.fontFamily
                text: (row.text ?? "").replace(/\n/g, " ⏎ ")
            }

            Loader {
                id: textLoader
                anchors.left: parent.left
                anchors.right: parent.right
                height: row.height
                active: row.editingText
                sourceComponent: TextArea {
                    id: textEditor
                    leftPadding: Theme.spacingMd
                    rightPadding: Theme.spacingMd
                    topPadding: 4
                    bottomPadding: 4
                    text: row.text ?? ""
                    wrapMode: TextArea.Wrap
                    color: Theme.c.subtitleCueGrid.foreground
                    selectionColor: Theme.c.subtitleCueGrid.selectedMarker
                    selectedTextColor: Theme.c.subtitleCueGrid.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    selectByMouse: true
                    background: Rectangle {
                        color: Theme.c.subtitleCueGrid.background
                        border.width: Theme.c.subtitleCueGrid.borderWidthFocus
                        border.color: Theme.c.subtitleCueGrid.borderFocus
                    }
                    Component.onCompleted: {
                        forceActiveFocus()
                        selectAll()
                        row.textEditorHeight = Qt.binding(() => implicitHeight)
                    }
                    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && (event.modifiers & Qt.ControlModifier)) {
                            row.panel.commitText(row.cueIndex, text)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            row.panel.cancelEdit()
                            event.accepted = true
                        }
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus && row.panel.editIndex === row.cueIndex && row.panel.editColumn === "text")
                            row.panel.commitText(row.cueIndex, text)
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.c.subtitleCueGrid.borderWidth
        color: Theme.c.subtitleCueGrid.border
        opacity: 0.4
    }
}
