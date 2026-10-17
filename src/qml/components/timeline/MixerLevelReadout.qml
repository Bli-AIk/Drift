import QtQuick
import Drift

// dB readout under the fader. Scroll nudges the level; double-click returns to 0 dB.
Rectangle {
    id: readout
    property var channel
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.spacingMd
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(parent.width - Theme.spacingLg, 64)
    height: 24
    radius: Theme.radiusXs
    color: readoutMouse.containsMouse ? Theme.popoverHover : Theme.panelAccent
    border.width: Theme.borderWidth
    border.color: Theme.panelBorder

    Text {
        anchors.centerIn: parent
        text: readout.channel.mixer.formatDb(readout.channel.curDb)
        color: readout.channel.armed || readout.channel.curDb > 0.05 ? Theme.destructive : Theme.panelForeground
        font.family: Theme.monoFontFamily
        font.pixelSize: Theme.fontSizeXs
    }

    MouseArea {
        id: readoutMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SizeVerCursor
        onDoubleClicked: readout.channel.volumeSet(1.0)
        onWheel: (wheel) => readout.channel.nudgeDb(wheel.angleDelta.y > 0 ? 0.5 : -0.5)
    }

    ThemedToolTip {
        visible: readoutMouse.containsMouse
        text: readout.channel.armed
              ? qsTr("Mic gain %1 dB (%2%) — scroll to adjust, double-click for 0 dB")
                    .arg(readout.channel.mixer.formatDb(readout.channel.curDb)).arg(Math.round(readout.channel.volume * 100))
              : qsTr("%1 dB — scroll to adjust, double-click for 0 dB").arg(readout.channel.mixer.formatDb(readout.channel.curDb))
    }
}
