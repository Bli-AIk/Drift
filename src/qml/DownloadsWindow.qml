import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Drift
// Marketplace downloads, plus the app update when one is downloading: what is running, what is waiting behind the concurrency cap, and
// what this session already finished. A window rather than a dialog because a download
// outlives the panel that started it — the Market tab can be closed, or the app switched to
// another project, while three clips are still being fetched.
//
// History is session-only by design. The files themselves land in the media bin and in the
// folder the user picked, so the list is a progress view, not a record to preserve.
ToolWindow {
    id: root

    width: 620
    height: 460
    minimumWidth: 460
    minimumHeight: 320
    title: qsTr("Downloads")
    color: Theme.c.downloadsWindow.background

    // The update row has the same shape as a marketplace job; its buttons route to Updates.
    readonly property var updateJob: Updates.downloadJob
    readonly property bool hasUpdateJob: updateJob.itemId !== undefined
    readonly property var jobs: (hasUpdateJob ? [updateJob] : []).concat(Market.downloads)
    readonly property int activeCount: Market.activeDownloadCount + (hasUpdateJob && updateJob.running ? 1 : 0)
    readonly property bool hasFinished: {
        if (hasUpdateJob && (updateJob.status === "failed" || updateJob.status === "cancelled"))
            return true
        const list = Market.downloads
        for (var i = 0; i < list.length; ++i) {
            if (list[i].finished)
                return true
        }
        return false
    }

    function show() {
        root.visible = true
        root.raise()
        root.requestActivate()
    }

    // The seven formatters moved to components/DownloadFormat.qml when the phone gained a
    // downloads sheet of its own; these forward so every call site in this file is unchanged.
    function formatBytes(n) { return DownloadFormat.formatBytes(n) }
    function formatSpeed(bytesPerSec) { return DownloadFormat.formatSpeed(bytesPerSec) }
    function formatRemaining(job) { return DownloadFormat.formatRemaining(job) }
    function kindGlyph(job) { return DownloadFormat.kindGlyph(job) }
    function statusGlyph(job) { return DownloadFormat.statusGlyph(job) }
    function statusColor(job) { return DownloadFormat.statusColor(job) }
    function detailLine(job) { return DownloadFormat.detailLine(job) }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Theme.pagePadding
            spacing: Theme.spacingSm

            Text {
                text: root.activeCount > 0
                      ? qsTr("%n active", "", root.activeCount)
                      : qsTr("No downloads running")
                color: Theme.c.downloadsWindow.foreground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeBase
                font.weight: Font.DemiBold
            }

            // Says why something sits at Waiting, so the cap does not read as a stall.
            ThemedLabel {
                visible: root.activeCount > Market.maxConcurrentDownloads
                text: qsTr("%1 at a time").arg(Market.maxConcurrentDownloads)
            }

            Item { Layout.fillWidth: true }

            ThemedButton {
                text: qsTr("Clear finished")
                variant: "ghost"
                enabled: root.hasFinished
                onClicked: {
                    Updates.clearDownloadState()
                    Market.clearFinishedDownloads()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.c.downloadsWindow.borderWidth
            color: Theme.c.downloadsWindow.border
        }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.jobs.length === 0
            glyph: Theme.icons.download
            title: qsTr("Nothing downloaded yet")
            hint: qsTr("Downloads from the Market tab show up here while they run.")
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.jobs.length > 0
            clip: true
            model: root.jobs
            spacing: 0
            ScrollBar.vertical: AppScrollBar { }

            delegate: DownloadsJobRow {
            }
        }
    }
}
