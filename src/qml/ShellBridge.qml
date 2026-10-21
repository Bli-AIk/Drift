pragma Singleton
import QtQuick

// The editor main window (Main or AndroidMain), reachable from any window. Panels may live in
// secondary windows, where Window.window is that window and not the one that owns the editor
// functions (configureAndAddAsset, openAddonManager, ...). Null until the shell's
// Component.onCompleted, so bindings must tolerate it.
QtObject {
    property var main: null
}
