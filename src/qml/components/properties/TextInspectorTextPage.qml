import QtQuick
import Drift

Column {
    id: root
    property var inspector
    property alias contentField: contentSection.contentField
    width: parent ? parent.width : implicitWidth
    spacing: Theme.spacingMd
    visible: inspector.textTab === "text"

    TextInspectorContentSection {
        id: contentSection
        width: parent.width
        inspector: root.inspector
    }
    TextInspectorFontSection {
        width: parent.width
        inspector: root.inspector
    }
    TextInspectorSpacingSection {
        width: parent.width
        inspector: root.inspector
    }
}
