import QtQuick
import QtQuick.Controls.Basic
import Drift

// One destination on the phone bottom rail: a selection pill, a glyph, a label.
AbstractButton {
    id: railBtn

    required property var entry
    property bool selected: false

    height: parent ? parent.height : 0
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: entry.label
    // Nav state has to reach assistive tech too, not just the tint below.
    Accessible.checkable: true
    Accessible.checked: railBtn.selected

    onClicked: Haptics.select()

    // Press feedback. On the root rather than the background so the label
    // dips with the icon, and via scale so packed slots do not reflow.
    scale: railBtn.down ? Theme.pressScale : 1.0

    Behavior on scale {
        NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
    }

    background: Item { }

    contentItem: ThemeSlot {
        slot: "AndroidRailButton"
        control: railBtn
        fallback: Component {
            Item {
                anchors.fill: parent

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    // Selection pill behind the glyph. The old rail signalled the
                    // active destination with tint alone — and the tint was
                    // Theme.primary, which sits at 1.69:1 on the light panel and so
                    // said nothing at all in light mode.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Theme.iconSizeLg + Theme.spacing2xl
                        height: Theme.iconSizeLg + Theme.spacingLg
                        radius: Theme.c.androidRailButton.radius
                        color: railBtn.selected ? Theme.c.androidRailButton.backgroundSelected
                                                : (railBtn.down ? Theme.c.androidRailButton.backgroundPressed
                                                                : "transparent")

                        Behavior on color {
                            ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                        }

                        IconGlyph {
                            anchors.centerIn: parent
                            glyph: railBtn.entry.icon
                            iconSize: Theme.iconSizeLg
                            iconColor: railBtn.selected ? Theme.c.androidRailButton.foregroundSelected
                                                        : Theme.c.androidRailButton.foreground
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: railBtn.entry.label
                        color: railBtn.selected ? Theme.c.androidRailButton.foregroundSelected
                                                : Theme.c.androidRailButton.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: railBtn.selected ? Font.Medium : Font.Normal
                    }
                }
            }
        }
    }
}
