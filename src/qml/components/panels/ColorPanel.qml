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
    readonly property var animatedKeys: target.animatedKeys || ([])
    property int tab: 0
    property var live: ({})
    property var expanded: ({})
    property var finishingSpecs: ({})
    property string applyStatus: ""
    property bool includeFinishing: false
    property bool compareWasOn: false
    property real compareDownAt: 0

    readonly property var tabs: [qsTr("Basic"), qsTr("Wheels"), qsTr("Curves"), qsTr("HSL"), qsTr("Finishing")]
    readonly property var lightSliders: [
        { key: "exposure", label: qsTr("Exposure"), from: -4, to: 4, def: 0, curvePower: 2 },
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
    readonly property var hueCurveKeys: ({ hue: "curveHueHue", sat: "curveHueSat", lum: "curveHueLum" })
    readonly property var hslBands: [
        { name: "red", param: "Red", label: qsTr("Red"), hue: 0 },
        { name: "orange", param: "Orange", label: qsTr("Orange"), hue: 30 },
        { name: "yellow", param: "Yellow", label: qsTr("Yellow"), hue: 60 },
        { name: "green", param: "Green", label: qsTr("Green"), hue: 120 },
        { name: "aqua", param: "Aqua", label: qsTr("Aqua"), hue: 180 },
        { name: "blue", param: "Blue", label: qsTr("Blue"), hue: 225 },
        { name: "purple", param: "Purple", label: qsTr("Purple"), hue: 270 },
        { name: "magenta", param: "Magenta", label: qsTr("Magenta"), hue: 300 }
    ]
    readonly property var hslSliders: [
        { suffix: "Hue", label: qsTr("Hue") },
        { suffix: "Sat", label: qsTr("Saturation") },
        { suffix: "Lum", label: qsTr("Luminance") }
    ]
    property int hslBand: 0
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
        return id === "" ? qsTr("None") : qsTr("Missing look")
    }

    readonly property var curves: ({
        master: parseCurve(params.curveMaster, false),
        r: parseCurve(params.curveR, false),
        g: parseCurve(params.curveG, false),
        b: parseCurve(params.curveB, false)
    })
    readonly property var hueCurves: ({
        hue: parseCurve(params.curveHueHue, true),
        sat: parseCurve(params.curveHueSat, true),
        lum: parseCurve(params.curveHueLum, true)
    })

    function parseCurve(v, hue) {
        let out = v
        if (typeof v === "string") {
            try {
                out = JSON.parse(v)
            } catch (e) {
                out = null
            }
        }
        const flat = hue ? 0.5 : 0
        const top = hue ? 0.5 : 1
        return Array.isArray(out) && out.length >= 2
            ? out : [{x: 0, y: flat, ease: "spline"}, {x: 1, y: top, ease: "spline"}]
    }

    function isAnimated(key) {
        return animatedKeys.indexOf(key) >= 0
    }

    function finishingAnimated(entry, key) {
        return (entry.animatedKeys || []).indexOf(key) >= 0
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

    function hslBandModified(param) {
        return hslSliders.some(s => Number(params["hsl" + param + s.suffix] ?? 0) !== 0)
    }

    function resetHslBand() {
        const band = hslBands[hslBand]
        colorState.beginEdit(qsTr("Reset %1").arg(band.label))
        hslSliders.forEach(s => colorState.setParam("hsl" + band.param + s.suffix, 0))
        colorState.commitEdit()
    }

    function selectHslBand(i) {
        hslBand = i
        bandRepeater.itemAt(i).forceActiveFocus()
    }

    function hslTrackGradient(suffix) {
        const hue = hslBands[hslBand].hue
        const shade = d => Qt.hsla((((hue + d) % 360) + 360) % 360 / 360, 1, 0.5, 1)
        if (suffix === "Hue")
            return [shade(-30), shade(0), shade(30)]
        if (suffix === "Sat")
            return [Qt.hsla(0, 0, 0.5, 1), shade(0)]
        return ["#000000", shade(0), "#ffffff"]
    }

    function resetCurrentTab() {
        if (tab === 0) {
            colorState.resetGroups(["Light", "Color", "Look"])
        } else if (tab === 1) {
            colorState.resetGroup("Wheels")
        } else if (tab === 2) {
            colorState.resetGroups(["Curves", "Hue Curves"])
        } else if (tab === 3) {
            colorState.resetGroup("HSL")
        }
    }

    focus: true
    activeFocusOnTab: true
    Shortcut {
        sequence: "\\"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: root.setBypass(!root.colorState.bypass)
    }

    onShownChanged: {
        if (!root.shown)
            root.setBypass(false)
    }
    function applyTabRequest() {
        const request = ShellBridge.colorTabRequest
        if (!request)
            return
        ShellBridge.colorTabRequest = null
        if (request.tab >= 0)
            root.tab = request.tab
    }
    Connections {
        target: ShellBridge
        function onColorTabRequestChanged() { root.applyTabRequest() }
    }
    Component.onCompleted: {
        applyTabRequest()
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
        onTapped: {
            if (!content.activeFocus)
                root.forceActiveFocus()
        }
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
            variant: root.colorState.bypass ? "primary" : "secondary"
            tooltip: qsTr("Click to toggle the original. Hold to see it while pressed (\\ key)")
            glyph: Theme.icons.eye
            // A short press flips the latch; a long press is a peek that ends on release.
            onPressed: {
                root.compareWasOn = root.colorState.bypass
                root.compareDownAt = Date.now()
                root.setBypass(true)
            }
            onReleased: {
                const held = Date.now() - root.compareDownAt
                root.setBypass(held > 300 ? root.compareWasOn : !root.compareWasOn)
            }
            onCanceled: root.setBypass(root.compareWasOn)
        }

        ThemedButton {
            text: qsTr("Apply to all…")
            enabled: !!root.target.canApplyToAll
            tooltip: root.target.canApplyToAll
                     ? qsTr("Copy this grade to every video, image and other visual clip on the timeline")
                     : qsTr("This grade already applies to the whole timeline. Select a clip to copy its grade to the others.")
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
                    visible: root.tab < 4
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

    Column {
        id: notes
        anchors.top: actions.visible ? actions.bottom : header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingMd
        anchors.rightMargin: Theme.spacingMd
        anchors.topMargin: height > 0 ? Theme.spacingMd : 0
        spacing: Theme.spacingSm
        visible: root.hasTarget

        Text {
            width: parent.width
            visible: (root.target.selectionCount ?? 0) > 1
            wrapMode: Text.WordWrap
            text: qsTr("Editing \"%1\" only. Use Apply to all to copy its grade to other clips.").arg(root.target.label)
            color: Theme.mutedForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
        }

        RowLayout {
            width: parent.width
            visible: !!root.target.hasGrade && root.target.gradeEnabled === false
            spacing: Theme.spacingMd

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("The grade is turned off.")
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
            ThemedButton {
                text: qsTr("Turn on")
                onClicked: root.colorState.enableGrade()
            }
        }

        RowLayout {
            width: parent.width
            visible: !!root.target.timelineGradeId
            spacing: Theme.spacingMd

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Timeline grade also applies.")
                color: Theme.mutedForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
            }
            ThemedButton {
                text: qsTr("Select it")
                onClicked: root.colorState.selectTimelineGrade()
            }
        }
    }

    Row {
        id: tabRow
        anchors.top: notes.bottom
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

        FocusScope {
            id: content
            x: Theme.spacingMd
            width: body.width - Theme.spacingMd * 2
            height: Math.max(basicTab.height, wheelsTab.height, curvesTab.height, hslTab.height, finishingTab.height)
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
                        curvePower: modelData.curvePower ?? 1
                        animated: root.isAnimated(modelData.key)
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
                        animated: root.isAnimated(modelData.key)
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
                    animated: root.isAnimated("lookAmount")
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
                            animated: root.isAnimated(modelData.key) || root.isAnimated(modelData.key + "Luma")
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

                SectionHeader {
                    title: qsTr("Hue Curves")
                    onResetRequested: root.colorState.resetGroup("Hue Curves")
                }
                CurveEditor {
                    width: Math.min(parent.width, 320)
                    height: implicitHeight
                    hueMode: true
                    curves: root.hueCurves
                    onBegan: root.colorState.beginEdit(qsTr("Adjust hue curves"))
                    onChanged: (channel, json) => root.colorState.setText(root.hueCurveKeys[channel], json)
                    onEnded: root.colorState.commitEdit()
                }
            }

            Column {
                id: hslTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 3
                height: visible ? implicitHeight : 0

                SectionHeader {
                    title: qsTr("HSL")
                    onResetRequested: root.colorState.resetGroup("HSL")
                }
                Row {
                    spacing: Theme.spacingSm
                    Repeater {
                        id: bandRepeater
                        model: root.hslBands
                        delegate: Item {
                            id: swatch
                            required property var modelData
                            required property int index
                            readonly property real inset: 4
                            readonly property bool selected: root.hslBand === index
                            width: Theme.controlHeightSm + inset * 2
                            height: width + 7
                            activeFocusOnTab: true
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: modelData.label
                            Accessible.checkable: true
                            Accessible.checked: selected

                            Rectangle {
                                width: swatch.width
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 2
                                border.color: Theme.focusRing
                                visible: swatch.selected || swatch.activeFocus
                            }

                            Rectangle {
                                x: swatch.inset
                                y: swatch.inset
                                width: Theme.controlHeightSm
                                height: width
                                radius: width / 2
                                color: Theme.c.colorGradeBands[swatch.modelData.name]
                            }

                            Rectangle {
                                x: (swatch.width - width) / 2
                                y: swatch.width + 1
                                width: 5
                                height: width
                                radius: width / 2
                                color: Theme.accentOnPanel
                                visible: root.hslBandModified(swatch.modelData.param)
                            }

                            HoverHandler {
                                id: swatchHover
                            }

                            ThemedToolTip {
                                visible: swatchHover.hovered
                                text: swatch.modelData.label
                            }

                            TapHandler {
                                onTapped: root.selectHslBand(swatch.index)
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Left)
                                    root.selectHslBand(Math.max(0, swatch.index - 1))
                                else if (event.key === Qt.Key_Right)
                                    root.selectHslBand(Math.min(root.hslBands.length - 1, swatch.index + 1))
                                else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                    root.hslBand = swatch.index
                                else
                                    return
                                event.accepted = true
                            }
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: Theme.controlHeightSm

                    Text {
                        anchors.left: parent.left
                        anchors.right: bandReset.left
                        anchors.rightMargin: Theme.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: root.hslBands[root.hslBand].label
                        color: Theme.mutedForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                    }

                    IconButton {
                        id: bandReset
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: Theme.icons.reset
                        tooltip: qsTr("Reset %1").arg(root.hslBands[root.hslBand].label)
                        buttonSize: Theme.controlHeightSm
                        enabled: root.hslBandModified(root.hslBands[root.hslBand].param)
                        onClicked: root.resetHslBand()
                    }
                }
                Repeater {
                    model: root.hslSliders
                    delegate: GradeSlider {
                        id: hslSlider
                        required property var modelData
                        readonly property string paramKey: "hsl" + root.hslBands[root.hslBand].param + modelData.suffix
                        width: hslTab.width
                        label: modelData.label
                        from: -1
                        to: 1
                        defaultValue: 0
                        gradient: root.hslTrackGradient(modelData.suffix)
                        animated: root.isAnimated(paramKey)
                        value: root.liveOr(paramKey, root.params[paramKey] ?? 0)
                        onBegan: root.colorState.beginEdit(qsTr("Adjust %1").arg(label))
                        onMoved: v => {
                            root.setLive(hslSlider.paramKey, v)
                            root.colorState.setParam(hslSlider.paramKey, v)
                        }
                        onEnded: {
                            root.colorState.commitEdit()
                            root.clearLive(hslSlider.paramKey)
                        }
                    }
                }
            }

            Column {
                id: finishingTab
                width: parent.width
                spacing: Theme.spacingMd
                visible: root.tab === 4
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
                                    readonly property var cardEntry: card.entry
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
            animated: root.finishingAnimated(loader.cardEntry, loader.spec.key)
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
