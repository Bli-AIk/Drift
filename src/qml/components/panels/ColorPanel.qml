pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Drift

PanelFrame {
    id: root

    property bool shown: false

    readonly property var colorState: EditorState.color
    readonly property var target: colorState.target
    readonly property bool hasTarget: !!target.hasTarget
    readonly property var params: target.params || ({})
    readonly property var finishing: target.finishing || ([])
    property int tab: 0
    property var live: ({})
    property var expanded: ({})
    property var finishingSpecs: ({})
    property string applyStatus: ""
    property bool includeFinishing: false

    readonly property var tabs: [qsTr("Basic"), qsTr("Wheels"), qsTr("Curves"), qsTr("Finishing")]
    readonly property var lightSliders: [
        { key: "exposure", label: qsTr("Exposure"), from: -4, to: 4, def: 0 },
        { key: "contrast", label: qsTr("Contrast"), from: -1, to: 1, def: 0 },
        { key: "highlights", label: qsTr("Highlights"), from: -1, to: 1, def: 0 },
        { key: "shadows", label: qsTr("Shadows"), from: -1, to: 1, def: 0 },
        { key: "whites", label: qsTr("Whites"), from: -1, to: 1, def: 0 },
        { key: "blacks", label: qsTr("Blacks"), from: -1, to: 1, def: 0 }
    ]
    readonly property var colorSliders: [
        { key: "temperature", label: qsTr("Temperature"), from: -1, to: 1, def: 0,
          gradient: ["#4f8dff", "#d9d9d9", "#ffb347"] },
        { key: "tint", label: qsTr("Tint"), from: -1, to: 1, def: 0,
          gradient: ["#5ccf7a", "#d9d9d9", "#e45cd0"] },
        { key: "saturation", label: qsTr("Saturation"), from: 0, to: 2, def: 1 },
        { key: "vibrance", label: qsTr("Vibrance"), from: -1, to: 1, def: 0 }
    ]
    readonly property var wheels: [
        { label: qsTr("Shadows"), key: "lift" },
        { label: qsTr("Midtones"), key: "gamma" },
        { label: qsTr("Highlights"), key: "gain" }
    ]
    readonly property var curveKeys: ({ master: "curveMaster", r: "curveR", g: "curveG", b: "curveB" })
    readonly property var finishingNames: ({
        "film_grain": qsTr("Film Grain"),
        "bloom_glow": qsTr("Glow"),
        "chromatic_aberration": qsTr("Chromatic Aberration"),
        "stylize.vignette": qsTr("Vignette"),
        "halation": qsTr("Halation")
    })

    readonly property string lookLabel: {
        const id = params.look || ""
        const list = colorState.looks
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === id)
                return list[i].label
        }
        return qsTr("None")
    }

    readonly property var curves: ({
        master: parseCurve(params.curveMaster),
        r: parseCurve(params.curveR),
        g: parseCurve(params.curveG),
        b: parseCurve(params.curveB)
    })

    function parseCurve(v) {
        let out = v
        if (typeof v === "string") {
            try {
                out = JSON.parse(v)
            } catch (e) {
                out = null
            }
        }
        return Array.isArray(out) && out.length >= 2
            ? out : [{x: 0, y: 0, ease: "spline"}, {x: 1, y: 1, ease: "spline"}]
    }

    function setLive(key, v) {
        const next = Object.assign({}, live)
        next[key] = v
        live = next
    }

    function clearLive(key) {
        const next = Object.assign({}, live)
        delete next[key]
        live = next
    }

    function liveOr(key, fallback) {
        return live[key] !== undefined ? live[key] : fallback
    }

    function finishingEntry(id) {
        for (let i = 0; i < finishing.length; ++i) {
            if (finishing[i].id === id)
                return finishing[i]
        }
        return ({ id: id, present: false, enabled: false, params: ({}) })
    }

    function isExpanded(id) {
        return expanded[id] === undefined ? true : expanded[id]
    }

    function toggleExpanded(id) {
        const next = Object.assign({}, expanded)
        next[id] = !isExpanded(id)
        expanded = next
    }

    function setBypass(on) {
        if (colorState.bypass !== on)
            colorState.bypass = on
    }

    function resetCurrentTab() {
        if (tab === 0) {
            colorState.resetGroup("Light")
            colorState.resetGroup("Color")
            colorState.resetGroup("Look")
        } else if (tab === 1) {
            colorState.resetGroup("Wheels")
        } else if (tab === 2) {
            colorState.resetGroup("Curves")
        }
    }

    focus: true
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backslash && !event.isAutoRepeat) {
            root.setBypass(true)
            event.accepted = true
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Backslash && !event.isAutoRepeat) {
            root.setBypass(false)
            event.accepted = true
        }
    }

    onShownChanged: {
        if (!root.shown)
            root.setBypass(false)
    }
    Component.onCompleted: {
        const specs = {}
        const catalog = colorState.finishingCatalog()
        for (let i = 0; i < catalog.length; ++i)
            specs[catalog[i].id] = colorState.finishingParamSpecs(catalog[i].id)
        finishingSpecs = specs
    }
    Component.onDestruction: setBypass(false)

    TapHandler {
        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.forceActiveFocus()
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: root.applyStatus = ""
    }

    component SectionHeader: Item {
        id: section
        property string title: ""
        signal resetRequested()
        width: parent ? parent.width : 200
        height: Theme.controlHeightSm

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: section.title
            color: Theme.panelForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
        }

        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.icons.reset
            tooltip: qsTr("Reset %1").arg(section.title)
            buttonSize: Theme.controlHeightSm
            onClicked: section.resetRequested()
        }
    }

    AssetsPanelHeader {
        id: header
        width: parent.width
        height: Theme.panelHeaderHeight
        title: root.hasTarget ? root.target.label : qsTr("No clip selected")
    }

    Flow {
        id: actions
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingMd
        visible: root.hasTarget

        ThemedButton {
            id: compareButton
            text: qsTr("Compare")
            tooltip: qsTr("Hold to see the original (or hold the \\ key)")
            glyph: Theme.icons.eye
            onPressed: root.setBypass(true)
            onReleased: root.setBypass(false)
            onCanceled: root.setBypass(false)
        }

        ThemedButton {
            text: qsTr("Apply to all…")
            tooltip: qsTr("Copy this grade to every clip on the timeline")
            onClicked: applyDialog.open()
        }

        IconButton {
            id: resetButton
            glyph: Theme.icons.reset
            tooltip: qsTr("Reset")
            onClicked: resetMenu.popup()

            ThemedContextMenu {
                id: resetMenu
                ThemedMenuItem {
                    text: qsTr("Reset everything")
                    onTriggered: root.colorState.resetAll()
                }
                ThemedMenuItem {
                    visible: root.tab < 3
                    height: visible ? implicitHeight : 0
                    text: qsTr("Reset this tab")
                    onTriggered: root.resetCurrentTab()
                }
            }
        }

        Text {
            visible: root.applyStatus.length > 0
            height: compareButton.height
            verticalAlignment: Text.AlignVCenter
            text: root.applyStatus
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }
    }

    Row {
        id: tabRow
        anchors.top: actions.visible ? actions.bottom : header.bottom
        anchors.left: parent.left
        anchors.margins: Theme.spacingMd
        spacing: Theme.spacingSm
        visible: root.hasTarget

        Repeater {
            model: root.tabs
            delegate: ThemedChip {
                required property int index
                required property string modelData
                text: modelData
                selected: root.tab === index
                onClicked: root.tab = index
            }
        }
    }

    Flickable {
        id: body
        anchors.top: tabRow.bottom
        anchors.topMargin: Theme.spacingMd
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.hasTarget
        clip: true
        contentWidth: width
        contentHeight: content.height + Theme.spacingLg * 2
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AppScrollBar { policy: ScrollBar.AsNeeded }

        Item {
            id: content
            x: Theme.spacingMd
            width: body.width - Theme.spacingMd * 2
            height: Math.max(basicTab.height, wheelsTab.height, curvesTab.height, finishingTab.height)
            opacity: root.colorState.bypass ? 0.5 : 1

            Column {
                id: basicTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 0
                height: visible ? implicitHeight : 0

                SectionHeader {
                    title: qsTr("Light")
                    onResetRequested: root.colorState.resetGroup("Light")
                }
                Repeater {
                    model: root.lightSliders
                    delegate: GradeSlider {
                        id: lightSlider
                        required property var modelData
                        width: basicTab.width
                        label: modelData.label
                        from: modelData.from
                        to: modelData.to
                        defaultValue: modelData.def
                        value: root.liveOr(modelData.key, root.params[modelData.key] ?? modelData.def)
                        onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
                        onMoved: v => {
                            root.setLive(modelData.key, v)
                            root.colorState.setParam(modelData.key, v)
                        }
                        onEnded: {
                            root.colorState.commitEdit()
                            root.clearLive(modelData.key)
                        }
                    }
                }

                SectionHeader {
                    title: qsTr("Color")
                    onResetRequested: root.colorState.resetGroup("Color")
                }
                Repeater {
                    model: root.colorSliders
                    delegate: GradeSlider {
                        required property var modelData
                        width: basicTab.width
                        label: modelData.label
                        from: modelData.from
                        to: modelData.to
                        defaultValue: modelData.def
                        gradient: modelData.gradient || []
                        value: root.liveOr(modelData.key, root.params[modelData.key] ?? modelData.def)
                        onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
                        onMoved: v => {
                            root.setLive(modelData.key, v)
                            root.colorState.setParam(modelData.key, v)
                        }
                        onEnded: {
                            root.colorState.commitEdit()
                            root.clearLive(modelData.key)
                        }
                    }
                }

                SectionHeader {
                    title: qsTr("Look")
                    onResetRequested: root.colorState.resetGroup("Look")
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.lookLabel
                    color: Theme.mutedForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                }
                GradeSlider {
                    width: basicTab.width
                    label: qsTr("Look Intensity")
                    from: 0
                    to: 1
                    defaultValue: 1
                    bipolar: false
                    value: root.liveOr("lookAmount", root.params.lookAmount ?? 1)
                    onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
                    onMoved: v => {
                        root.setLive("lookAmount", v)
                        root.colorState.setParam("lookAmount", v)
                    }
                    onEnded: {
                        root.colorState.commitEdit()
                        root.clearLive("lookAmount")
                    }
                }
            }

            Column {
                id: wheelsTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 1
                height: visible ? implicitHeight : 0

                SectionHeader {
                    title: qsTr("Wheels")
                    onResetRequested: root.colorState.resetGroup("Wheels")
                }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingLg
                    Repeater {
                        model: root.wheels
                        delegate: ColorWheel {
                            id: wheel
                            required property var modelData
                            readonly property var vec: root.params[modelData.key] || [0, 0]
                            size: Math.min(160, wheelsTab.width)
                            label: modelData.label
                            offset: Qt.point(vec[0], vec[1])
                            luma: root.liveOr(modelData.key + "Luma", root.params[modelData.key + "Luma"] ?? 0)
                            onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
                            onOffsetMoved: (x, y) => root.colorState.setVec2(modelData.key, x, y)
                            onLumaMoved: v => {
                                root.setLive(modelData.key + "Luma", v)
                                root.colorState.setParam(modelData.key + "Luma", v)
                            }
                            onEnded: {
                                root.colorState.commitEdit()
                                root.clearLive(modelData.key + "Luma")
                            }
                        }
                    }
                }
            }

            Column {
                id: curvesTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 2
                height: visible ? implicitHeight : 0

                SectionHeader {
                    title: qsTr("Curves")
                    onResetRequested: root.colorState.resetGroup("Curves")
                }
                CurveEditor {
                    width: Math.min(parent.width, 320)
                    height: implicitHeight
                    curves: root.curves
                    histogram: root.colorState.scopes.active
                               ? "image://color/scope/histogram?s=" + root.colorState.scopes.serial : ""
                    onBegan: root.colorState.beginEdit(qsTr("Adjust curves"))
                    onChanged: (channel, json) => root.colorState.setText(root.curveKeys[channel], json)
                    onEnded: root.colorState.commitEdit()
                }
            }

            Column {
                id: finishingTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 3
                height: visible ? implicitHeight : 0

                Repeater {
                    model: Object.keys(root.finishingNames)
                    delegate: Rectangle {
                        id: card
                        required property string modelData
                        readonly property var entry: root.finishingEntry(modelData)
                        readonly property bool open: entry.present && root.isExpanded(modelData)
                        width: finishingTab.width
                        height: cardColumn.height + Theme.spacingMd * 2
                        radius: Theme.radiusMd
                        color: Theme.panelSecondaryBg

                        Column {
                            id: cardColumn
                            x: Theme.spacingMd
                            y: Theme.spacingMd
                            width: parent.width - Theme.spacingMd * 2
                            spacing: Theme.spacingMd

                            Item {
                                width: parent.width
                                height: Theme.controlHeight

                                TapHandler {
                                    enabled: card.entry.present
                                    onTapped: root.toggleExpanded(card.modelData)
                                }

                                IconGlyph {
                                    id: chevron
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: card.entry.present
                                    glyph: card.open ? Theme.icons.chevronDown : Theme.icons.chevronRight
                                    iconSize: 14
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: card.entry.present ? chevron.iconSize + Theme.spacingSm : 0
                                    anchors.right: controls.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    text: root.finishingNames[card.modelData]
                                    color: Theme.panelForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                }

                                Row {
                                    id: controls
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingSm

                                    ThemedSwitch {
                                        anchors.verticalCenter: parent.verticalCenter
                                        checked: card.entry.present && card.entry.enabled
                                        onToggled: {
                                            if (!card.entry.present)
                                                root.colorState.toggleFinishing(card.modelData, true)
                                            else
                                                root.colorState.setFinishingEnabled(card.modelData, checked)
                                        }
                                    }
                                    IconButton {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: card.entry.present
                                        glyph: Theme.icons.x
                                        tooltip: qsTr("Remove")
                                        buttonSize: Theme.controlHeightSm
                                        onClicked: root.colorState.toggleFinishing(card.modelData, false)
                                    }
                                }
                            }

                            Repeater {
                                model: card.open ? (root.finishingSpecs[card.modelData] || []) : []
                                delegate: Loader {
                                    id: paramLoader
                                    required property var modelData
                                    readonly property var spec: modelData
                                    readonly property string fxId: card.modelData
                                    readonly property string liveKey: card.modelData + ":" + spec.key
                                    readonly property var current: card.entry.params[spec.key]
                                    width: cardColumn.width
                                    sourceComponent: spec.type === "bool" ? boolParam
                                                     : spec.type === "color" ? colorParam
                                                     : (spec.type === "float" || spec.type === "int")
                                                       ? floatParam : null
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: floatParam
        GradeSlider {
            readonly property var loader: parent
            label: loader.spec.label
            from: loader.spec.min
            to: loader.spec.max
            defaultValue: Number(loader.spec.default)
            bipolar: false
            stepSize: loader.spec.step > 0 ? loader.spec.step : (to - from) / 100
            value: root.liveOr(loader.liveKey, loader.current ?? defaultValue)
            onBegan: root.colorState.beginFinishingEdit(
                         loader.fxId, qsTr("Adjust %1").arg(label))
            onMoved: v => {
                root.setLive(loader.liveKey, v)
                root.colorState.setFinishingParam(loader.fxId, loader.spec.key, v)
            }
            onEnded: {
                root.colorState.commitEdit()
                root.clearLive(loader.liveKey)
            }
        }
    }

    Component {
        id: boolParam
        RowLayout {
            readonly property var loader: parent
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: loader.spec.label
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
            ThemedSwitch {
                checked: !!loader.current
                onToggled: root.colorState.setFinishingParam(
                               loader.fxId, loader.spec.key, checked ? 1 : 0)
            }
        }
    }

    Component {
        id: colorParam
        RowLayout {
            readonly property var loader: parent
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: loader.spec.label
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
            ColorSwatchField {
                hex: typeof loader.current === "string" ? loader.current : "#ffffff"
                onEdited: value => root.colorState.setFinishingColor(
                              loader.fxId, loader.spec.key, value)
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: !root.hasTarget
        glyph: Theme.icons.sliders
        title: qsTr("Select a clip to color grade it")
        hint: qsTr("Or grade the whole timeline at once.")
        actionText: qsTr("Grade whole timeline")
        onActionTriggered: root.colorState.gradeWholeTimeline()
    }

    ThemedDialog {
        id: applyDialog
        title: qsTr("Apply to all clips")
        acceptText: qsTr("Apply")
        onAccepted: {
            const n = root.colorState.applyToAll(root.includeFinishing)
            root.applyStatus = qsTr("Applied to %n clip(s)", "", n)
            statusTimer.restart()
        }

        contentItem: ThemedCheckBox {
            text: qsTr("Include finishing effects")
            checked: root.includeFinishing
            onToggled: root.includeFinishing = checked
        }
    }
}
