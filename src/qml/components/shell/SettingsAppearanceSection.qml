import QtQuick
import Drift

// Theme picker, import, and window translucency. First section in Settings.
SettingsSectionCard {
    id: root

    title: qsTr("Appearance")

    function chooseTheme(themeId) {
        if (themeId === "dark" || themeId === "light")
            EditorState.preferences.setDarkModePreference(themeId === "dark")
        if (themeId !== "system" && themeId !== "dark" && themeId !== "light") {
            const themes = ThemeManager.themes
            for (let i = 0; i < themes.length; ++i) {
                const theme = themes[i]
                if (theme.id === themeId && theme.hasOverrides && !theme.trusted) {
                    trustDialog.prompt(themeId)
                    return
                }
            }
        }
        if (!ThemeManager.select(themeId))
            Toasts.error(ThemeManager.lastError || qsTr("Could not use that theme."))
    }

    readonly property bool activeHasVariants: {
        const themes = ThemeManager.themes
        for (let i = 0; i < themes.length; ++i) {
            if (themes[i].id === ThemeManager.selection)
                return !!themes[i].hasVariants
        }
        return false
    }

    SettingsThemeList {
        onThemeChosen: (themeId) => root.chooseTheme(themeId)
        onRevokeTrust: (themeId) => ThemeManager.setThemeTrusted(themeId, false)
    }

    ThemedLabel {
        width: parent.width
        visible: ThemeManager.appearanceFollowsTheme
        wrapMode: Text.WordWrap
        color: Theme.c.settingsAppearanceSection.foreground
        text: qsTr("This theme is %1 only. Light and Dark leave it and return to the system theme.")
              .arg(ThemeManager.effectiveVariant === "dark" ? qsTr("dark") : qsTr("light"))
    }

    ThemedLabel {
        width: parent.width
        visible: root.activeHasVariants
        wrapMode: Text.WordWrap
        color: Theme.c.settingsAppearanceSection.foreground
        text: qsTr("This theme has a dark and a light variant. The header toggle switches between them.")
    }

    SettingsAppearanceActions {
        onImported: (themeId) => root.chooseTheme(themeId)
    }

    SettingsAppearanceTranslucency { }

    // Popups are not column children. The dialog reparents itself to the overlay.
    Item {
        visible: false
        ThemeTrustDialog {
            id: trustDialog

            onTrustChosen: {
                ThemeManager.setThemeTrusted(trustDialog.themeId, true)
                if (!ThemeManager.select(trustDialog.themeId))
                    Toasts.error(ThemeManager.lastError || qsTr("Could not use that theme."))
            }
            onSkipChosen: {
                if (!ThemeManager.select(trustDialog.themeId))
                    Toasts.error(ThemeManager.lastError || qsTr("Could not use that theme."))
            }
        }
    }
}
