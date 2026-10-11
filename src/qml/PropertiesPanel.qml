import QtQuick
import QtQuick.Controls.Basic
import Drift
import "components"
import "components/properties"

PanelFrame {
    id: root

    // Android bottom sheet: keep the inspector tab rail but drop the panel border
    // chrome that fights the sheet frame.
    property bool sheetMode: false
    border.width: sheetMode ? 0 : 1
    radius: sheetMode ? 0 : Theme.radiusSm
    color: sheetMode ? "transparent" : Theme.panelBackground

    // Raised by the Effects / Audio empty states; Main wires them to the
    // assets panel so the browse CTAs actually take the user somewhere.
    signal browseEffectsRequested()
    // Sheet mode only: a subtitle row was tapped and its text is edited in the keyboard composer.
    signal cueEditRequested(int index)

    // -1 while the prompt is saving the whole stack; otherwise the one effect it was raised on.
    property int savePresetEffectIndex: -1
    signal browseAudioEffectsRequested()

    // selectedClipData is a QVariantMap; key the binding on an explicit revision
    // so nested fields such as effects refresh after project edits.
    property int clipDataRevision: 0
    readonly property var clipData: {
        void clipDataRevision
        return EditorState.selectedClipData
    }
    readonly property bool hasSelection: !!root.clipData && Object.keys(root.clipData).length > 0
    readonly property var transition: EditorState.selectedTransitionData
    readonly property bool hasTransitionSelection: !!transition && Object.keys(transition).length > 0
    readonly property int transitionTabIndex: tabIndexOf("transition")
    readonly property string clipKind: hasSelection ? (root.clipData.kind || "") : ""
    // What the selected clip supports, from AppController's inspectorCaps(). Tabs list the caps
    // they need in `tabs` below.
    readonly property var caps: hasSelection ? (root.clipData.caps || []) : []

    // Inspector view state that outlives the tab being unloaded.
    QtObject {
        id: inspectorUi
        property bool sizeLinked: true
        property string textTab: "text"
        property string animSlot: "in"
        property string animCategory: ""
        property var textExpandedLayerIds: ({})
        property real contentFieldHeight: 96
        property var shapeExpandedLayerIds: ({})
    }

    property int activeTab: 0
    readonly property string currentTabId: tabs[activeTab].id
    readonly property bool keyframesTab: !!tabs[activeTab].keyframes

    // Kept for SubtitleEditor, which formats cue times through it.
    function formatSeconds(value) {
        return Number(value || 0).toFixed(2)
    }

    Connections {
        target: EditorState
        function onSelectionChanged() {
            root.clipDataRevision++
            root.syncAdjustmentTab()
            root.syncActiveTab()
        }
        function onSelectedClipDataChanged() {
            root.clipDataRevision++
            root.syncActiveTab()
        }
        function onSelectedTransitionDataChanged() {
            if (root.hasTransitionSelection)
                root.activeTab = root.transitionTabIndex
        }
        function onTracksChanged() {
            root.clipDataRevision++
        }
        // A text clip added with no text lands in its content field. addTextClip has already
        // selected it, so the Text tab exists; callLater lets the tab switch settle before the
        // focus lands on a child of the page that was hidden a moment ago.
        function onInlineTextEditRequested(trackIndex, clipIndex) {
            if (!root.tabVisible("text"))
                return
            root.activeTab = root.textTabIndex
            Qt.callLater(() => {
                if (textLoader.item)
                    textLoader.item.focusContent()
            })
        }
    }

    Component.onCompleted: {
        root.syncActiveTab()
    }

    // Rail order: clip identity → geometry/timing → compositing / FX.
    // `group` drives hairlines between the next *visible* tab of a different group.
    // A tab shows only when the clip has every cap in `needs`, so a tab or clip kind that nobody
    // described stays hidden instead of turning up on every clip. `opens` is the adjustment
    // payload the tab edits: selecting that adjustment jumps straight to it. `keyframes` marks a
    // tab that edits keyframeable properties, which is when the timeline opens its keyframe lane.
    // Audio is one: volume is keyframeable and edited there.
    readonly property var tabs: [
        { id: "general", label: qsTr("General"), icon: Theme.icons.info, group: 0, needs: [] },
        { id: "text", label: qsTr("Text"), icon: Theme.icons.type, group: 0, needs: ["textStyled"] },
        { id: "shape", label: qsTr("Shape"), icon: Theme.icons.shapes, group: 0, needs: ["shape"] },
        { id: "vector", label: qsTr("Motion"), icon: Theme.icons.layers, group: 0, needs: ["vector"] },
        { id: "model3d", label: qsTr("3D Model"), icon: Theme.icons.box, group: 0, needs: ["model3d"] },
        { id: "pdf", label: qsTr("PDF"), icon: Theme.icons.fileText, group: 0, needs: ["pdf"] },
        { id: "subtitles", label: qsTr("Subtitles"), icon: Theme.icons.captions, group: 0, needs: ["subtitle"] },
        { id: "transform", label: qsTr("Transform"), icon: Theme.icons.maximize, group: 1,
          needs: ["transformable"], opens: "adj:transform", keyframes: true },
        { id: "camera", label: qsTr("Camera"), icon: Theme.icons.video, group: 1,
          needs: ["adj:camera"], opens: "adj:camera" },
        { id: "stabilize", label: qsTr("Stabilization"), icon: Theme.icons.locateFixed, group: 1,
          needs: ["stabilizable"], keyframes: true },
        { id: "animation", label: qsTr("Animation"), icon: Theme.icons.sparkles, group: 1, needs: ["animatable"] },
        { id: "audio", label: qsTr("Audio"), icon: Theme.icons.volumeHigh, group: 1, needs: ["audible"], keyframes: true },
        { id: "speed", label: qsTr("Speed"), icon: Theme.icons.gauge, group: 1, needs: ["retimable"] },
        { id: "blending", label: qsTr("Blending"), icon: Theme.icons.blend, group: 2, needs: ["blendable"] },
        // Masks and effect stacks live on the adjustments pinned to a clip, and those adjustments
        // are what you select to edit them. A clip can carry several mask adjustments, and
        // reporting one clip-shaped stack for it could only ever show the first.
        { id: "masks", label: qsTr("Masks"), icon: Theme.icons.mask, group: 2,
          needs: ["maskable"], opens: "adj:mask", keyframes: true },
        { id: "effects", label: qsTr("Effects"), icon: Theme.icons.wand, group: 2,
          needs: ["adj:videoEffects"], opens: "adj:videoEffects", keyframes: true },
        { id: "audioEffects", label: qsTr("Audio FX"), icon: Theme.icons.audioLines, group: 2,
          needs: ["adj:audioEffects"], opens: "adj:audioEffects" },
        { id: "transition", label: qsTr("Transition"), icon: Theme.icons.chevronsRight, group: 2,
          needs: ["transitionable"] }
    ]

    function tabVisible(tabId) {
        const tab = root.tabs[tabIndexOf(tabId)]
        return !!tab && tab.needs.every(cap => root.caps.indexOf(cap) >= 0)
    }

    // Hairline after this index when the next visible tab belongs to another group.
    function showSeparatorAfter(index) {
        const cur = root.tabs[index]
        if (!tabVisible(cur.id))
            return false
        for (let i = index + 1; i < root.tabs.length; ++i) {
            const next = root.tabs[i]
            if (!tabVisible(next.id))
                continue
            return next.group !== cur.group
        }
        return false
    }

    function tabIndexOf(id) {
        for (let i = 0; i < root.tabs.length; i++) {
            if (root.tabs[i].id === id)
                return i
        }
        return -1
    }
    readonly property int textTabIndex: tabIndexOf("text")

    // Selecting an adjustment is how you edit its payload, so it opens the pane that edits
    // one — the same courtesy selecting a transition already gets. A video-effects adjustment
    // also offers the Masks tab, but its effect stack is what you came for, so `opens` decides
    // and not tab order.
    function syncAdjustmentTab() {
        for (let i = 0; i < root.tabs.length; i++) {
            const opens = root.tabs[i].opens
            if (opens && root.caps.indexOf(opens) >= 0) {
                root.activeTab = i
                return
            }
        }
    }

    // A tab that the new selection does not support would leave an empty pane. With nothing
    // selected the tab is kept, so reselecting a clip lands where you were.
    function syncActiveTab() {
        if (root.hasSelection && !root.tabVisible(root.currentTabId))
            root.activeTab = 0
    }

    // Tell the timeline to show its subtitle-cue lane only while the Subtitles tab is open.
    Binding {
        target: EditorState
        property: "subtitleEditing"
        value: root.currentTabId === "subtitles" && root.clipKind === "subtitle"
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(260, root.width - 32)
        visible: !root.hasSelection
        spacing: 16

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 48
            radius: Theme.radiusMd
            color: "transparent"
            border.width: 1
            border.color: Theme.panelBorder

            IconGlyph {
                anchors.centerIn: parent
                glyph: Theme.icons.sliders
                iconSize: 22
                iconColor: Theme.mutedForeground
            }
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("It's empty here")
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeBase
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.sheetMode
                  ? qsTr("Tap a clip on the timeline to edit its properties")
                  : qsTr("Click a clip on the timeline to edit its properties")
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }

    Item {
        id: content
        anchors.fill: parent
        visible: root.hasSelection

        // === Phone: a labelled tab strip across the top ===============================
        // The desktop rail below is a column of thirteen unlabelled icons. Inside a
        // bottom sheet it has to scroll on its own axis, stands a second scrollbar
        // next to the content's, and spends a fifth of an already narrow sheet
        // saying nothing that can be read at a glance.
        Item {
            id: tabStripHost
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            visible: root.sheetMode
            // Icon over label: the label alone identifies a tab, but the icon is
            // what the eye finds again after the first time.
            readonly property real tabChipHeight: 58
            height: visible ? tabChipHeight + Theme.spacingLg * 2 : 0

            // Keeps the selected tab on screen when it is picked from off the end,
            // and when the visible set changes with the clip kind.
            function ensureTabVisible() {
                const item = tabStripRepeater.itemAt(root.activeTab)
                if (!item || !item.visible)
                    return
                const left = tabStripRow.x + item.x
                const right = left + item.width
                const maxX = Math.max(0, tabStrip.contentWidth - tabStrip.width)
                if (left - Theme.pagePadding < tabStrip.contentX)
                    tabStrip.contentX = Math.max(0, left - Theme.pagePadding)
                else if (right + Theme.pagePadding > tabStrip.contentX + tabStrip.width)
                    tabStrip.contentX = Math.min(maxX, right + Theme.pagePadding - tabStrip.width)
            }

            Connections {
                target: root
                // callLater: a tab change can also change which tabs exist, and the
                // Row has not repositioned yet when the signal arrives.
                function onActiveTabChanged() { Qt.callLater(tabStripHost.ensureTabVisible) }
                function onClipKindChanged() { Qt.callLater(tabStripHost.ensureTabVisible) }
            }

            Flickable {
                id: tabStrip
                anchors.fill: parent
                contentWidth: tabStripRow.width + Theme.pagePadding * 2
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Row {
                    id: tabStripRow
                    x: Theme.pagePadding
                    height: tabStrip.height
                    spacing: Theme.spacingSm

                    Repeater {
                        id: tabStripRepeater
                        model: root.tabs
                        // Not a ThemedChip: that one's contentItem is a single Text,
                        // and stacking a glyph over the label needs two rows.
                        delegate: AbstractButton {
                            id: tabChip
                            required property int index
                            required property var modelData

                            readonly property bool current: root.activeTab === tabChip.index

                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.tabVisible(tabChip.modelData.id)
                            height: tabStripHost.tabChipHeight
                            implicitWidth: Math.max(Theme.controlHeight + Theme.spacing2xl,
                                                    tabChipLabel.implicitWidth + Theme.spacingXl * 2)
                            hoverEnabled: true
                            focusPolicy: Qt.StrongFocus

                            Accessible.role: Accessible.PageTab
                            Accessible.name: tabChip.modelData.label
                            Accessible.checked: tabChip.current

                            scale: tabChip.down ? Theme.pressScale : 1.0

                            Behavior on scale {
                                NumberAnimation { duration: Theme.durationPress; easing.type: Theme.easing }
                            }

                            onClicked: {
                                Haptics.select()
                                root.activeTab = tabChip.index
                            }

                            background: Rectangle {
                                radius: Theme.radiusMd
                                color: tabChip.current
                                       ? Theme.primary
                                       : (tabChip.down ? Theme.panelMuted : Theme.panelAccent)
                                border.width: Theme.borderWidth
                                border.color: tabChip.current ? Theme.primary : Theme.panelBorder

                                Behavior on color {
                                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                                }
                                Behavior on border.color {
                                    ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easing }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: Theme.borderWidthFocus
                                    border.color: Theme.focusRing
                                    visible: tabChip.visualFocus
                                }
                            }

                            // Wrapped in an Item so the two rows sit centred in the
                            // pill; a bare Column would stack them against its top.
                            contentItem: Item {
                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingSm

                                    IconGlyph {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        glyph: tabChip.modelData.icon
                                        iconSize: Theme.iconSizeLg
                                        iconColor: tabChip.current ? Theme.primaryForeground
                                                                   : Theme.panelForeground
                                    }

                                    Text {
                                        id: tabChipLabel
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tabChip.modelData.label
                                        color: tabChip.current ? Theme.primaryForeground
                                                               : Theme.panelForeground
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: tabChip.current ? Font.Medium : Font.Normal
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.borderWidth
                color: Theme.panelBorder
            }
        }

        // === Desktop: vertical icon rail + tab content ================================
        // Up/Down move between tabs once the rail has focus.
        // Flickable so short panel heights can still reach lower icons.
        Flickable {
            id: propertiesTabRail
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: root.sheetMode ? 0 : Theme.tabRailWidth
            visible: !root.sheetMode
            contentWidth: width
            contentHeight: propertiesTabRailColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            ScrollBar.vertical: AppScrollBar {
                policy: propertiesTabRail.contentHeight > propertiesTabRail.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            Accessible.role: Accessible.PageTabList

            Keys.onUpPressed: function(event) {
                let next = root.activeTab
                for (let step = 0; step < root.tabs.length; ++step) {
                    next = (next - 1 + root.tabs.length) % root.tabs.length
                    if (root.tabVisible(root.tabs[next].id)) {
                        root.activeTab = next
                        break
                    }
                }
                event.accepted = true
            }
            Keys.onDownPressed: function(event) {
                let next = root.activeTab
                for (let step = 0; step < root.tabs.length; ++step) {
                    next = (next + 1) % root.tabs.length
                    if (root.tabVisible(root.tabs[next].id)) {
                        root.activeTab = next
                        break
                    }
                }
                event.accepted = true
            }

            Column {
                id: propertiesTabRailColumn
                width: parent.width
                topPadding: Theme.spacingSm
                spacing: Theme.spacingXs

                Repeater {
                    model: root.tabs
                    delegate: Column {
                        required property int index
                        required property var modelData

                        width: parent.width
                        spacing: 0
                        // Collapse so hidden contextual tabs leave no rail gap.
                        visible: root.tabVisible(modelData.id)
                        height: visible ? implicitHeight : 0

                        IconButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            glyph: modelData.icon
                            variant: "ghost"
                            tooltip: modelData.label
                            active: root.activeTab === index
                            onClicked: root.activeTab = index

                            Accessible.role: Accessible.PageTab
                            Accessible.name: modelData.label
                            Accessible.checked: root.activeTab === index
                        }

                        Item {
                            visible: root.showSeparatorAfter(index)
                            width: parent.width
                            height: visible ? Theme.spacingLg + Theme.borderWidth : 0

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconSizeSm
                                height: Theme.borderWidth
                                radius: height / 2
                                color: Theme.panelBorder
                                opacity: 0.85
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: railDivider
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: propertiesTabRail.right
            width: root.sheetMode ? 0 : Theme.borderWidth
            visible: !root.sheetMode
            color: Theme.panelBorder
        }

        Flickable {
            id: tabFlick
            anchors.top: tabStripHost.bottom
            anchors.left: railDivider.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.currentTabId !== "subtitles"
            contentWidth: width
            // Include topPadding so the last controls stay reachable (SettingsTab pattern).
            contentHeight: tabColumn.height + Theme.spacing3xl
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            ScrollBar.vertical: AppScrollBar {
                policy: tabFlick.contentHeight > tabFlick.height
                        ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            }

            // Tall tabs (Audio/Effects) leave contentY deep; reset when switching.
            Connections {
                target: root
                function onActiveTabChanged() {
                    tabFlick.contentY = 0
                    tabColumn.opacity = 0
                    tabFadeIn.restart()
                }
            }

            // Fade the new tab in rather than hard-cutting to it. Fade-in only,
            // not a crossfade: the inspectors share a Column, which excludes
            // invisible items from layout, so overlapping two of them would
            // double-count height and jump the panel mid-transition.
            NumberAnimation {
                id: tabFadeIn
                target: tabColumn
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.durationBase
                easing.type: Theme.easing
            }

            Column {
                id: tabColumn
                x: Theme.pagePadding
                width: parent.width - Theme.pagePadding * 2
                // Sections need to read apart on a phone, where the whole pane is
                // about two of them tall.
                spacing: root.sheetMode ? Theme.spacing2xl : Theme.spacingXl
                topPadding: root.sheetMode ? Theme.spacing2xl : Theme.pagePadding

                Text {
                    // The strip above already names the tab, in a size you can read.
                    visible: !root.sheetMode
                    text: root.tabs[root.activeTab].label
                    color: Theme.mutedForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.Medium
                }

                // Only the open tab is instantiated. Hidden inspectors used to stay alive and
                // re-read the whole selected clip on every edit; the view state that has to
                // outlive a tab switch is kept in inspectorUi instead.
                Loader {
                    active: root.currentTabId === "general"
                    visible: active
                    sourceComponent: Component { GeneralInspector { width: tabColumn.width } }
                }

                Loader {
                    id: textLoader
                    active: root.currentTabId === "text"
                    visible: active
                    sourceComponent: Component {
                        TextInspector {
                            width: tabColumn.width
                            textTab: inspectorUi.textTab
                            animSlot: inspectorUi.animSlot
                            animCategory: inspectorUi.animCategory
                            expandedLayerIds: inspectorUi.textExpandedLayerIds
                            contentFieldHeight: inspectorUi.contentFieldHeight
                            onTextTabChanged: inspectorUi.textTab = textTab
                            onAnimSlotChanged: inspectorUi.animSlot = animSlot
                            onAnimCategoryChanged: inspectorUi.animCategory = animCategory
                            onExpandedLayerIdsChanged: inspectorUi.textExpandedLayerIds = expandedLayerIds
                            onContentFieldHeightChanged: inspectorUi.contentFieldHeight = contentFieldHeight
                        }
                    }
                }

                Loader {
                    active: root.currentTabId === "transform"
                    visible: active
                    sourceComponent: Component {
                        TransformInspector {
                            width: tabColumn.width
                            sizeLinked: inspectorUi.sizeLinked
                            onSizeLinkedChanged: inspectorUi.sizeLinked = sizeLinked
                            positionLinked: EditorState.positionLinked
                            onPositionLinkedChanged: EditorState.positionLinked = positionLinked
                        }
                    }
                }

                Loader {
                    active: root.currentTabId === "camera"
                    visible: active
                    sourceComponent: Component { CameraInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "stabilize"
                    visible: active
                    sourceComponent: Component { StabilizeInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "animation"
                    visible: active
                    sourceComponent: Component { AnimationInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "audio"
                    visible: active
                    sourceComponent: Component { AudioInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "speed"
                    visible: active
                    sourceComponent: Component { SpeedFadeInspector { width: tabColumn.width } }
                }

                // Its kind box and duration field commit on their own (activate / editing
                // finished), so nothing is lost when the tab switch destroys it.
                Loader {
                    active: root.currentTabId === "transition"
                    visible: active
                    sourceComponent: Component { TransitionInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "blending"
                    visible: active
                    sourceComponent: Component { BlendingInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "shape"
                    visible: active
                    sourceComponent: Component {
                        ShapeInspector {
                            width: tabColumn.width
                            expandedLayerIds: inspectorUi.shapeExpandedLayerIds
                            onExpandedLayerIdsChanged: inspectorUi.shapeExpandedLayerIds = expandedLayerIds
                        }
                    }
                }

                Loader {
                    active: root.currentTabId === "vector"
                    visible: active
                    sourceComponent: Component { VectorInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "model3d"
                    visible: active
                    sourceComponent: Component { Model3DInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "pdf"
                    visible: active
                    sourceComponent: Component { PdfInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "masks"
                    visible: active
                    sourceComponent: Component { MasksInspector { width: tabColumn.width } }
                }

                Loader {
                    active: root.currentTabId === "effects"
                    visible: active
                    sourceComponent: Component {
                        EffectsInspector {
                            width: tabColumn.width
                            onBrowseEffectsRequested: root.browseEffectsRequested()
                            onSaveEffectPresetRequested: function(effectIndex) {
                                root.savePresetEffectIndex = effectIndex
                                effectPresetNameDialog.openWith(
                                    effectIndex < 0 ? qsTr("Save effect preset")
                                                    : qsTr("Save effect as preset"),
                                    root.hasSelection ? (root.clipData.name || "") : "")
                            }
                        }
                    }
                }

                Loader {
                    active: root.currentTabId === "audioEffects"
                    visible: active
                    sourceComponent: Component {
                        AudioEffectsInspector {
                            width: tabColumn.width
                            onBrowseAudioEffectsRequested: root.browseAudioEffectsRequested()
                        }
                    }
                }
            }
        }

        // Full-height editor with its own internal cue list scrolling, so it
        // sits beside the tab Flickable rather than inside it.
        Loader {
            anchors.top: tabStripHost.bottom
            anchors.left: railDivider.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            active: root.currentTabId === "subtitles"
            visible: active
            sourceComponent: Component {
                SubtitleEditor {
                    clip: root.hasSelection ? root.clipData : null
                    formatSeconds: root.formatSeconds
                    compactEdit: root.sheetMode
                    onCueEditRequested: index => root.cueEditRequested(index)
                }
            }
        }
    }

    NameDialog {
        id: effectPresetNameDialog
        placeholder: qsTr("My look")
        onSubmitted: function(name) {
            if (root.savePresetEffectIndex < 0)
                EditorState.saveClipEffectsAsPreset(EditorState.selectedTrack,
                                                    EditorState.selectedClip, name)
            else
                EditorState.saveEffectAsPreset(EditorState.selectedTrack,
                                               EditorState.selectedClip,
                                               root.savePresetEffectIndex, name)
            root.savePresetEffectIndex = -1
        }
        onRejected: root.savePresetEffectIndex = -1
    }
}
