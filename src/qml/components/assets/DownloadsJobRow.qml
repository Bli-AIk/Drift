import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Drift
// One download in the downloads window: file, progress, retry and cancel.
Rectangle {
    id: root
    required property var modelData
    width: ListView.view ? ListView.view.width : 0
    height: rowLayout.implicitHeight + Theme.spacingXl * 2
    color: rowHover.hovered ? Theme.popoverHover : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
    }

    HoverHandler { id: rowHover }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: Theme.spacingXl
        spacing: Theme.spacingXl

        // The file leads and the status rides on it as an emblem, the way a
        // download list is normally read: what it is first, how it is going second.
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: Theme.spacing3xl + Theme.spacingLg
            implicitHeight: Theme.spacing3xl + Theme.spacingLg
            radius: Theme.radiusSm
            color: Theme.panelAccent

            IconGlyph {
                anchors.centerIn: parent
                glyph: DownloadFormat.kindGlyph(root.modelData)
                iconSize: Theme.iconSizeBase
                iconColor: Theme.mutedForeground
            }

            // Painted on the window background rather than the tile so the
            // emblem stays legible where it overhangs the corner.
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -Theme.spacingXs
                width: Theme.spacingXl + Theme.spacingXs
                height: width
                radius: width / 2
                color: Theme.appBackground

                IconGlyph {
                    anchors.centerIn: parent
                    glyph: DownloadFormat.statusGlyph(root.modelData)
                    iconSize: Theme.iconSizeMd
                    iconColor: DownloadFormat.statusColor(root.modelData)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSm

            Text {
                Layout.fillWidth: true
                text: root.modelData.title
                color: Theme.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                elide: Text.ElideRight
            }

            // Shown only once the length is known: a bar parked at 0 through
            // "Preparing…" reads as a stall, and the phase line says more.
            ThemedProgressBar {
                Layout.fillWidth: true
                visible: root.modelData.status === "downloading"
                         && Number(root.modelData.bytesTotal) > 0
                value: Number(root.modelData.progress || 0)
            }

            Text {
                Layout.fillWidth: true
                text: DownloadFormat.detailLine(root.modelData)
                color: root.modelData.status === "failed" ? Theme.destructive
                                                        : Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
            }

            // Where the file went. Worth showing because the user chose it, and
            // a download that landed somewhere they did not expect is the thing
            // they will come here to check.
            Text {
                Layout.fillWidth: true
                visible: root.modelData.status === "done"
                         && String(root.modelData.destinationDir).length > 0
                text: root.modelData.destinationDir
                color: Theme.mutedForeground
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeXs
                elide: Text.ElideLeft
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            visible: root.modelData.status === "downloading"
                     && Number(root.modelData.bytesTotal) > 0
            text: Math.round(Number(root.modelData.progress || 0) * 100) + "%"
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            visible: root.modelData.retryable
            glyph: Theme.icons.refresh
            tooltip: qsTr("Try again")
            onClicked: root.modelData.kind === "update"
                       ? Updates.retryDownload()
                       : Market.retryDownload(root.modelData.itemId)
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            visible: !root.modelData.finished
            glyph: Theme.icons.x
            tooltip: qsTr("Cancel")
            enabled: root.modelData.status !== "preparing"
            onClicked: root.modelData.kind === "update"
                       ? Updates.cancelDownload()
                       : Market.cancelDownload(root.modelData.itemId)
        }
    }
}
