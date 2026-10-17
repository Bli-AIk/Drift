#pragma once

#include <QFileSystemWatcher>
#include <QObject>
#include <QQmlPropertyMap>
#include <QStringList>
#include <QUrl>
#include <QVariant>
#include <QtQml/qqmlregistration.h>

#include <optional>

// One JSON theme document, exposed as a fixed set of QQmlPropertyMaps.
//
// The map objects themselves stay put across loadTheme() / setVariant(). Values
// are pushed with insert(), so a QML binding to ThemeManager.semantic.panel.border
// (or Theme.c.button.primary.background, once a component group exists) keeps
// watching the same object and updates when that key changes. Replacing the map
// would drop those subscriptions.
class ThemeManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QQmlPropertyMap *palette READ palette CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *semantic READ semantic CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *components READ components CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *metrics READ metrics CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *typography READ typography CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *motion READ motion CONSTANT)
    Q_PROPERTY(QQmlPropertyMap *window READ window CONSTANT)
    Q_PROPERTY(QString currentTheme READ currentTheme NOTIFY themeChanged)
    Q_PROPERTY(QStringList availableThemes READ availableThemes NOTIFY availableThemesChanged)
    Q_PROPERTY(bool hotReload READ hotReload WRITE setHotReload NOTIFY hotReloadChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    // Process-wide instance QML binds to. main() publishes it with
    // registerSingleton(); a ThemeManager constructed anywhere else stays private.
    static ThemeManager *shared();
    static void registerSingleton();

    QQmlPropertyMap *palette() const { return m_palette; }
    QQmlPropertyMap *semantic() const { return m_semantic; }
    QQmlPropertyMap *components() const { return m_components; }
    QQmlPropertyMap *metrics() const { return m_metrics; }
    QQmlPropertyMap *typography() const { return m_typography; }
    QQmlPropertyMap *motion() const { return m_motion; }
    QQmlPropertyMap *window() const { return m_window; }

    QString currentTheme() const { return m_currentTheme; }
    QStringList availableThemes() const;
    bool hotReload() const { return m_hotReload; }
    void setHotReload(bool enabled);

    Q_INVOKABLE QVariant token(const QString &dottedPath) const;
    // Built-in dark/light documents, independent of whichever theme is active.
    // Theme.qml uses this for the _dark / _light maps, which stay constant while
    // setVariant() swaps the live groups.
    Q_INVOKABLE QVariant builtinToken(const QString &variant, const QString &dottedPath) const;
    Q_INVOKABLE bool loadTheme(const QString &nameOrPath);
    Q_INVOKABLE void reload();
    // Selects the built-in dark or light theme. A loaded user theme is left in
    // place; Theme.qml still calls this on every darkMode change.
    Q_INVOKABLE void setVariant(const QString &variant);
    // Trusted QML overrides land in a later wave. Empty until then.
    Q_INVOKABLE QUrl overrideUrl(const QString &slot) const;

signals:
    void themeChanged();
    void hotReloadChanged();
    void availableThemesChanged();

private:
    struct Loaded {
        QString name;
        QString path;
        QString variant;
        bool user = false;
        QVariantMap document;
    };

    QString locate(const QString &nameOrPath, QString *error) const;
    QString pathForThemeName(const QString &name, QString *error) const;
    QVariantMap compose(const QString &path, QStringList *stack, QString *error) const;
    std::optional<Loaded> readTheme(const QString &nameOrPath, QString *error) const;
    void apply(const Loaded &loaded);
    void updateWatch();

    QQmlPropertyMap *m_palette = nullptr;
    QQmlPropertyMap *m_semantic = nullptr;
    QQmlPropertyMap *m_components = nullptr;
    QQmlPropertyMap *m_metrics = nullptr;
    QQmlPropertyMap *m_typography = nullptr;
    QQmlPropertyMap *m_motion = nullptr;
    QQmlPropertyMap *m_window = nullptr;

    QFileSystemWatcher m_watcher;
    QString m_currentTheme;
    QString m_sourcePath;
    QString m_requestedVariant = QStringLiteral("dark");
    QVariantMap m_resolved;
    QVariantMap m_builtinDark;
    QVariantMap m_builtinLight;
    bool m_userTheme = false;
    bool m_hotReload = false;
    bool m_inReload = false;

private slots:
    void onThemeFileChanged(const QString &path);
};
