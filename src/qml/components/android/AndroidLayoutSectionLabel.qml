import QtQuick
import Drift

// Section headings all sit on the same page margin; the scrolling chip rows below
// them carry that margin as padding instead, so they can bleed to the screen edge.
ThemedLabel {
    x: Theme.androidPagePadding
    tone: "default"
    size: "sm"
}
