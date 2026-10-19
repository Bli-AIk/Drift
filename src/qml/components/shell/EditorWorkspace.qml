import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import Drift

Column {
    id: root
    signal downloadsRequested()
    property alias editorHeader: editorHeader
    property alias rootSplit: rootSplit
    property alias outerSplit: outerSplit
    property alias innerSplit: innerSplit
    property alias assetsPanel: assetsPanel
    property alias previewPanel: previewPanel
    property alias propertiesPanel: propertiesPanel
    property alias timelinePanel: timelinePanel
    anchors.fill: parent
    spacing: 0
    // The start screen sits on top of this document rather than replacing it (see
    // the StartScreen instance below), so without this the editor underneath was
    // still fully live — clickable through any gap and, worse, still reachable by
    // keyboard even though nothing of it is visible. Disabling blocks mouse input
    // and keyboard focus for the whole subtree, not just the pointer.
    enabled: !Window.window.showStartScreen

    EditorHeader {
        id: editorHeader
        width: parent.width
        visible: !Window.window.previewFullscreen
        onDownloadsRequested: root.downloadsRequested()
    }

    Item {
        width: parent.width
        // Clamped so the editor body never takes a negative height while the
        // window is being resized toward its minimum.
        height: Math.max(0, parent.height
                            - (Window.window.previewFullscreen ? 0 : Theme.headerHeight))

        // Two workspaces (issue #46). Landscape is the classic three-pane row
        // above the timeline. Portrait lifts the preview out into a full-height
        // column on the right, so a 9:16 frame is bounded by the window height
        // instead of by the height of the top row — where it renders
        // postage-stamp small. Only the preview moves between the two; assets,
        // properties and the timeline keep their slots either way.
        SplitView {
            id: rootSplit
            anchors.fill: parent
            // Edge-to-edge in fullscreen; the usual page padding otherwise.
            anchors.margins: Window.window.previewFullscreen ? 0 : Theme.pagePadding
            anchors.topMargin: 0
            orientation: Qt.Horizontal
            spacing: Theme.panelGap

            handle: PanelSplitHandle { view: rootSplit }

            // Container.removeItem() *destroys* what it removes — takeItem() is
            // the one that hands the item back. That distinction matters here:
            // the preview owns the video sink and the GL runtime, so rebuilding
            // it (via removeItem, or a Loader) would tear down the renderer and
            // drop playback state on every workspace switch. Moving the one live
            // instance keeps the switch free.
            function relocatePreview() {
                const wantRoot = Window.window.portraitWorkspace
                if (wantRoot === (previewPanel.SplitView.view === rootSplit))
                    return
                const from = wantRoot ? innerSplit : rootSplit
                for (let i = 0; i < from.count; ++i) {
                    if (from.itemAt(i) === previewPanel) {
                        from.takeItem(i)
                        break
                    }
                }
                // Index 1 either way: after the assets panel in the landscape
                // row, after the editing stack in the portrait column.
                if (wantRoot)
                    rootSplit.insertItem(1, previewPanel)
                else
                    innerSplit.insertItem(1, previewPanel)
            }

            // The preview is declared in its landscape slot below, so a session
            // that starts portrait needs one move once the tree exists. Also
            // covers a layout flip that lands before this point during startup —
            // relocatePreview() is a no-op when nothing has to move.
            Component.onCompleted: relocatePreview()

            // Each split reapplies the fractions measured against its own extent,
            // and saves them once a handle drag ends. Reapplying on another split's
            // resize would fight a drag in progress there.
            onWidthChanged: Window.window.applyPreviewFraction()
            onResizingChanged: {
                if (!resizing && Window.window.portraitWorkspace && rootSplit.width > 0)
                    LayoutMemory.setPanelFraction(Window.window.workspaceLayout + "/preview",
                                                  previewPanel.width / rootSplit.width)
            }

            SplitView {
                id: outerSplit
                SplitView.fillWidth: true
                orientation: Qt.Vertical
                spacing: Theme.panelGap

                handle: PanelSplitHandle { view: outerSplit }

                // In the portrait workspace the preview is a sibling of this
                // whole stack, so fullscreen has to collapse the stack itself —
                // hiding only the panels inside it would leave the preview
                // confined to its column. SplitView drops hidden items from the
                // layout, so this hands the window to the preview.
                visible: !(Window.window.previewFullscreen && Window.window.portraitWorkspace)

                onHeightChanged: Window.window.applyEditorRowFraction()
                onResizingChanged: {
                    if (!resizing && outerSplit.height > 0)
                        LayoutMemory.setPanelFraction(Window.window.workspaceLayout + "/editorRow",
                                                      innerSplit.height / outerSplit.height)
                }

                SplitView {
                    id: innerSplit
                    // Sized against the enclosing SplitView by id. `parent` here
                    // is the SplitView's own content item, which makes these
                    // percentage constraints self-referential during a resize.
                    // In fullscreen the timeline is hidden, so the normal 30–85%
                    // band would leave a dead strip below the preview.
                    //
                    // Never set a fixed minimum larger than the current parent
                    // size: on the first layout pass width/height are 0, and
                    // Qt SplitView asserts when maximum < minimum (qBound).
                    SplitView.preferredHeight: Window.window.previewFullscreen
                                               ? outerSplit.height : outerSplit.height * 0.5
                    SplitView.minimumHeight: Window.window.previewFullscreen
                                             ? outerSplit.height
                                             : Math.min(outerSplit.height, outerSplit.height * 0.3)
                    SplitView.maximumHeight: Window.window.previewFullscreen
                                             ? outerSplit.height
                                             : Math.max(SplitView.minimumHeight, outerSplit.height * 0.85)
                    orientation: Qt.Horizontal
                    spacing: Theme.panelGap

                    handle: PanelSplitHandle { view: innerSplit }

                    onWidthChanged: Window.window.applySidePanelFractions()
                    onResizingChanged: {
                        if (resizing || innerSplit.width <= 0)
                            return
                        const prefix = Window.window.workspaceLayout + "/"
                        LayoutMemory.setPanelFraction(prefix + "assets", assetsPanel.width / innerSplit.width)
                        LayoutMemory.setPanelFraction(prefix + "properties",
                                                      propertiesPanel.width / innerSplit.width)
                    }

                    AssetsPanel {
                        id: assetsPanel
                        visible: !Window.window.previewFullscreen
                        // A quarter of the row alongside the preview. In portrait
                        // the preview is gone from this row and the properties
                        // panel — last, and the only one without a fill — soaks up
                        // everything left over, so an unchanged quarter here left
                        // the library at a third of the inspector's width. Half
                        // splits the row evenly between the two instead.
                        SplitView.preferredWidth: Math.max(0, innerSplit.width
                                                           * (Window.window.portraitWorkspace ? 0.5 : 0.25))
                        // Cap mins to available width so 200+320+240 never exceeds a
                        // zero/partial first layout pass (Qt asserts max < min).
                        SplitView.minimumWidth: Math.min(200, Math.max(0, innerSplit.width * 0.2))
                    }

                    // Declared in its landscape slot; rootSplit.relocatePreview()
                    // moves this same instance out to the portrait column.
                    PreviewPanel {
                        id: previewPanel
                        previewFullscreen: Window.window.previewFullscreen
                        onFullscreenRequested: Window.window.togglePreviewFullscreen()
                        // Landscape: the pane that absorbs the slack in the top
                        // row. Portrait: a sized column, with the editing stack
                        // taking the slack instead — except in fullscreen, where
                        // the stack is hidden and the preview is all there is.
                        SplitView.fillWidth: !Window.window.portraitWorkspace || Window.window.previewFullscreen
                        // Portrait default: wide enough for the tall frame once
                        // the panel's transport row and gutters are discounted,
                        // capped so the libraries and timeline keep a usable
                        // share. Ignored while fillWidth is set, and replaced
                        // outright once the user drags the handle — SplitView
                        // writes this attached property, which drops the binding.
                        SplitView.preferredWidth: Math.max(0, Math.min(rootSplit.width * 0.4,
                                                                       (rootSplit.height - 72) * 9 / 16))
                        SplitView.minimumWidth: Window.window.portraitWorkspace
                                                ? Math.min(260, Math.max(0, rootSplit.width * 0.2))
                                                : Math.min(320, Math.max(0, innerSplit.width * 0.3))
                    }

                    PropertiesPanel {
                        id: propertiesPanel
                        visible: !Window.window.previewFullscreen
                        SplitView.preferredWidth: Math.max(0, innerSplit.width * 0.25)
                        SplitView.minimumWidth: Math.min(240, Math.max(0, innerSplit.width * 0.2))
                        // Empty-state browse CTAs jump the assets panel to the
                        // matching library tab.
                        onBrowseEffectsRequested: assetsPanel.showTab("effects")
                        onBrowseAudioEffectsRequested: assetsPanel.showTab("sounds")
                    }
                }

                TimelinePanel {
                    id: timelinePanel
                    visible: !Window.window.previewFullscreen
                    keyframesTab: propertiesPanel.keyframesTab
                    SplitView.preferredHeight: Math.max(0, outerSplit.height * 0.5)
                    SplitView.minimumHeight: Math.min(140, Math.max(0, outerSplit.height * 0.2))
                }
            }

            // The preview is inserted here, after the editing stack, while the
            // portrait workspace is active.
        }
    }
}
