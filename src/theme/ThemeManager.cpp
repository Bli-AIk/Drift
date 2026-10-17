#include "ThemeManager.h"

#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QQmlEngine>
#include <QtQml/qqml.h>
#include <QRegularExpression>
#include <QStandardPaths>

namespace {

constexpr auto kDarkResource = ":/themes/dark.json";
constexpr auto kLightResource = ":/themes/light.json";

const QStringList kGroups = {
    QStringLiteral("palette"),
    QStringLiteral("semantic"),
    QStringLiteral("components"),
    QStringLiteral("metrics"),
    QStringLiteral("typography"),
    QStringLiteral("motion"),
    QStringLiteral("window"),
};

// A reference chain longer than this is treated as a cycle even if the detector
// missed it. Themes are a few dozen tokens deep at most.
constexpr int kMaxReferenceDepth = 64;

QString userThemesDirectory()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/themes");
}

bool isBuiltinPath(const QString &path)
{
    return path == QLatin1String(kDarkResource) || path == QLatin1String(kLightResource);
}

QString fallbackName(const QString &path)
{
    const QFileInfo info(path);
    if (info.fileName() == QLatin1String("theme.json"))
        return QFileInfo(info.path()).fileName();
    return info.completeBaseName();
}

QQmlPropertyMap *makeMap(QObject *parent)
{
    QQmlPropertyMap *map = QQmlPropertyMap::create(parent);
    // The engine must not delete maps ThemeManager still owns. Bindings hold
    // the nested objects for the life of the theme manager.
    QQmlEngine::setObjectOwnership(map, QQmlEngine::CppOwnership);
    return map;
}

QQmlPropertyMap *asMap(const QVariant &value)
{
    if (auto *map = value.value<QQmlPropertyMap *>())
        return map;
    return qobject_cast<QQmlPropertyMap *>(value.value<QObject *>());
}

bool lookup(const QVariantMap &root, const QString &dotted, QVariant *out)
{
    const QStringList parts = dotted.split(QLatin1Char('.'), Qt::SkipEmptyParts);
    if (parts.isEmpty())
        return false;
    QVariant current = root;
    for (const QString &part : parts) {
        if (current.typeId() != QMetaType::QVariantMap)
            return false;
        const QVariantMap map = current.toMap();
        if (!map.contains(part))
            return false;
        current = map.value(part);
    }
    *out = current;
    return true;
}

QVariant lookupPath(const QVariantMap &root, const QString &dotted)
{
    QVariant value;
    if (!lookup(root, dotted, &value))
        return {};
    return value;
}

bool isColorLiteral(const QString &text)
{
    static const QRegularExpression re(
        QStringLiteral("^#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$"));
    return re.match(text).hasMatch();
}

bool isReference(const QString &text)
{
    static const QRegularExpression re(
        QStringLiteral("^\\$[A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z_][A-Za-z0-9_]*)*$"));
    return re.match(text).hasMatch();
}

QVariantMap readObject(const QString &path, QString *error, bool warn = true)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        *error = QStringLiteral("cannot open %1: %2").arg(path, file.errorString());
        if (warn)
            qWarning("theme: %s", qPrintable(*error));
        return {};
    }
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        const QString detail = parseError.error == QJsonParseError::NoError
                                   ? QStringLiteral("expected an object")
                                   : parseError.errorString();
        *error = QStringLiteral("invalid JSON in %1: %2").arg(path, detail);
        if (warn)
            qWarning("theme: %s", qPrintable(*error));
        return {};
    }
    return doc.object().toVariantMap();
}

QString readThemeName(const QString &path)
{
    // Name lookup walks every file in the themes directory. The caller reports
    // a real load failure; scanning must not warn about files it only peeks at.
    QString error;
    const QVariantMap doc = readObject(path, &error, false);
    if (!error.isEmpty())
        return {};
    const QVariant name = doc.value(QStringLiteral("name"));
    if (name.typeId() != QMetaType::QString)
        return {};
    return name.toString().trimmed();
}

bool validateStructure(const QVariantMap &doc, const QString &path, QString *error)
{
    auto fail = [&](const QString &message) {
        *error = message;
        qWarning("theme: %s (%s)", qPrintable(message), qPrintable(path));
        return false;
    };

    const auto requireString = [&](const char *key, bool allowMissing) {
        if (!doc.contains(QLatin1String(key)))
            return allowMissing;
        if (doc.value(QLatin1String(key)).typeId() != QMetaType::QString
            || doc.value(QLatin1String(key)).toString().trimmed().isEmpty())
            return fail(QStringLiteral("\"%1\" must be a non-empty string").arg(QLatin1String(key)));
        return true;
    };
    if (!requireString("name", true) || !requireString("extends", true))
        return false;
    if (doc.contains(QStringLiteral("variant"))) {
        const QString variant = doc.value(QStringLiteral("variant")).toString();
        if (variant != QLatin1String("dark") && variant != QLatin1String("light"))
            return fail(QStringLiteral("\"variant\" must be \"dark\" or \"light\""));
    }

    for (auto it = doc.cbegin(); it != doc.cend(); ++it) {
        if (it.key() == QLatin1String("name") || it.key() == QLatin1String("variant")
            || it.key() == QLatin1String("extends") || kGroups.contains(it.key()))
            continue;
        qWarning("theme: unknown key \"%s\" in %s", qPrintable(it.key()), qPrintable(path));
    }

    for (const QString &group : kGroups) {
        if (!doc.contains(group))
            continue;
        if (doc.value(group).typeId() != QMetaType::QVariantMap)
            return fail(QStringLiteral("\"%1\" must be an object").arg(group));
    }

    if (doc.contains(QStringLiteral("palette"))) {
        const QVariantMap palette = doc.value(QStringLiteral("palette")).toMap();
        for (auto it = palette.cbegin(); it != palette.cend(); ++it) {
            if (it.value().typeId() != QMetaType::QString)
                return fail(QStringLiteral("palette.%1 must be a string").arg(it.key()));
        }
    }

    if (doc.contains(QStringLiteral("window"))) {
        const QVariantMap window = doc.value(QStringLiteral("window")).toMap();
        if (window.contains(QStringLiteral("translucent"))
            && window.value(QStringLiteral("translucent")).typeId() != QMetaType::Bool)
            return fail(QStringLiteral("window.translucent must be a boolean"));
        if (window.contains(QStringLiteral("backdrop"))
            && window.value(QStringLiteral("backdrop")).typeId() != QMetaType::QString)
            return fail(QStringLiteral("window.backdrop must be a string"));
        if (window.contains(QStringLiteral("backgroundOpacity"))) {
            const QVariant opacity = window.value(QStringLiteral("backgroundOpacity"));
            const int opacityType = opacity.typeId();
            if (opacityType != QMetaType::Double && opacityType != QMetaType::Int
                && opacityType != QMetaType::LongLong)
                return fail(QStringLiteral("window.backgroundOpacity must be a number"));
            const double value = opacity.toDouble();
            if (value < 0.0 || value > 1.0)
                qWarning("theme: window.backgroundOpacity %g is outside 0..1 in %s", value,
                         qPrintable(path));
        }
    }
    return true;
}

QVariant deepMerge(const QVariant &base, const QVariant &overlay)
{
    if (base.typeId() == QMetaType::QVariantMap && overlay.typeId() == QMetaType::QVariantMap) {
        QVariantMap result = base.toMap();
        const QVariantMap over = overlay.toMap();
        for (auto it = over.cbegin(); it != over.cend(); ++it)
            result.insert(it.key(), deepMerge(result.value(it.key()), it.value()));
        return result;
    }
    return overlay;
}

QVariant resolveTree(const QVariant &value, const QVariantMap &root, QStringList *stack,
                     const QString &path, const QString &filePath)
{
    if (value.typeId() == QMetaType::QString) {
        const QString text = value.toString().trimmed();
        if (!text.startsWith(QLatin1Char('$')))
            return text;
        if (!isReference(text)) {
            qWarning("theme: malformed reference \"%s\" at %s in %s", qPrintable(text),
                     qPrintable(path), qPrintable(filePath));
            return text;
        }
        const QString ref = text.mid(1);
        if (stack->contains(ref) || stack->size() >= kMaxReferenceDepth) {
            qWarning("theme: reference cycle at %s involving $%s in %s", qPrintable(path),
                     qPrintable(ref), qPrintable(filePath));
            return text;
        }
        QVariant target;
        if (!lookup(root, ref, &target)) {
            qWarning("theme: unresolved reference $%s at %s in %s", qPrintable(ref),
                     qPrintable(path), qPrintable(filePath));
            return text;
        }
        stack->append(ref);
        const QVariant resolved = resolveTree(target, root, stack, ref, filePath);
        stack->removeLast();
        return resolved;
    }
    if (value.typeId() == QMetaType::QVariantMap) {
        QVariantMap result;
        const QVariantMap map = value.toMap();
        for (auto it = map.cbegin(); it != map.cend(); ++it) {
            const QString childPath = path.isEmpty() ? it.key() : path + QLatin1Char('.') + it.key();
            result.insert(it.key(), resolveTree(it.value(), root, stack, childPath, filePath));
        }
        return result;
    }
    if (value.typeId() == QMetaType::QVariantList) {
        QVariantList result;
        const QVariantList list = value.toList();
        for (int i = 0; i < list.size(); ++i) {
            const QString childPath = path + QLatin1Char('[') + QString::number(i) + QLatin1Char(']');
            result.append(resolveTree(list.at(i), root, stack, childPath, filePath));
        }
        return result;
    }
    return value;
}

QVariant coerceTree(const QVariant &value, const QString &path, const QString &filePath)
{
    if (value.typeId() == QMetaType::QString) {
        const QString text = value.toString();
        if (!text.startsWith(QLatin1Char('#')))
            return text;
        if (!isColorLiteral(text)) {
            qWarning("theme: invalid color \"%s\" at %s in %s", qPrintable(text), qPrintable(path),
                     qPrintable(filePath));
            return text;
        }
        const QColor color(text);
        if (!color.isValid()) {
            qWarning("theme: invalid color \"%s\" at %s in %s", qPrintable(text), qPrintable(path),
                     qPrintable(filePath));
            return text;
        }
        return color;
    }
    if (value.typeId() == QMetaType::QVariantMap) {
        QVariantMap result;
        const QVariantMap map = value.toMap();
        for (auto it = map.cbegin(); it != map.cend(); ++it) {
            const QString childPath = path.isEmpty() ? it.key() : path + QLatin1Char('.') + it.key();
            result.insert(it.key(), coerceTree(it.value(), childPath, filePath));
        }
        return result;
    }
    if (value.typeId() == QMetaType::QVariantList) {
        QVariantList result;
        const QVariantList list = value.toList();
        for (int i = 0; i < list.size(); ++i) {
            const QString childPath = path + QLatin1Char('[') + QString::number(i) + QLatin1Char(']');
            result.append(coerceTree(list.at(i), childPath, filePath));
        }
        return result;
    }
    return value;
}

void removeKey(QQmlPropertyMap *map, const QString &key)
{
    QQmlPropertyMap *child = asMap(map->value(key));
    map->clear(key);
    if (child)
        child->deleteLater();
}

void syncMap(QQmlPropertyMap *map, const QVariantMap &data)
{
    const QStringList existing = map->keys();
    for (const QString &key : existing) {
        if (!data.contains(key))
            removeKey(map, key);
    }
    for (auto it = data.cbegin(); it != data.cend(); ++it) {
        if (it.value().typeId() == QMetaType::QVariantMap) {
            QQmlPropertyMap *child = asMap(map->value(it.key()));
            if (!child) {
                child = makeMap(map);
                map->insert(it.key(), QVariant::fromValue(static_cast<QObject *>(child)));
            }
            syncMap(child, it.value().toMap());
            continue;
        }
        if (QQmlPropertyMap *old = asMap(map->value(it.key()))) {
            map->clear(it.key());
            old->deleteLater();
        }
        if (map->value(it.key()) != it.value())
            map->insert(it.key(), it.value());
    }
}

} // namespace

ThemeManager *ThemeManager::shared()
{
    static ThemeManager instance;
    return &instance;
}

void ThemeManager::registerSingleton()
{
    // qmlRegisterSingletonInstance warns and no-ops if called twice. Tests and
    // main() share this entry point, so the second call must stay quiet.
    static bool registered = false;
    if (registered)
        return;
    registered = true;
    qmlRegisterSingletonInstance("Drift", 1, 0, "ThemeManager", shared());
}

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent)
    , m_palette(makeMap(this))
    , m_semantic(makeMap(this))
    , m_components(makeMap(this))
    , m_metrics(makeMap(this))
    , m_typography(makeMap(this))
    , m_motion(makeMap(this))
    , m_window(makeMap(this))
    , m_watcher(this)
{
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &ThemeManager::onThemeFileChanged);

    QString error;
    if (auto dark = readTheme(QStringLiteral("dark"), &error))
        m_builtinDark = dark->document;
    else
        qWarning("theme: %s", qPrintable(error));
    error.clear();
    if (auto light = readTheme(QStringLiteral("light"), &error))
        m_builtinLight = light->document;
    else
        qWarning("theme: %s", qPrintable(error));

    if (!m_builtinDark.isEmpty()) {
        Loaded dark;
        dark.name = m_builtinDark.value(QStringLiteral("name")).toString();
        if (dark.name.isEmpty())
            dark.name = QStringLiteral("dark");
        dark.path = QString::fromLatin1(kDarkResource);
        dark.variant = QStringLiteral("dark");
        dark.user = false;
        dark.document = m_builtinDark;
        apply(dark);
    }
}

QStringList ThemeManager::availableThemes() const
{
    QStringList names{QStringLiteral("dark"), QStringLiteral("light")};
    QStringList user;
    const QDir dir(userThemesDirectory());
    if (!dir.exists())
        return names;

    const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (const QFileInfo &info : entries) {
        QString path;
        if (info.isDir()) {
            path = info.filePath() + QStringLiteral("/theme.json");
            if (!QFile::exists(path))
                continue;
        } else if (info.suffix().compare(QLatin1String("json"), Qt::CaseInsensitive) == 0) {
            path = info.absoluteFilePath();
        } else {
            continue;
        }

        QString name = readThemeName(path);
        if (name.isEmpty())
            name = info.isDir() ? info.fileName() : info.completeBaseName();
        if (name == QLatin1String("dark") || name == QLatin1String("light")) {
            qWarning("theme: user theme \"%s\" collides with a built-in (%s)", qPrintable(name),
                     qPrintable(path));
            continue;
        }
        if (names.contains(name) || user.contains(name)) {
            qWarning("theme: duplicate theme name \"%s\" (%s)", qPrintable(name), qPrintable(path));
            continue;
        }
        user.append(name);
    }
    user.sort();
    names.append(user);
    return names;
}

QVariant ThemeManager::token(const QString &dottedPath) const
{
    return lookupPath(m_resolved, dottedPath);
}

QVariant ThemeManager::builtinToken(const QString &variant, const QString &dottedPath) const
{
    if (variant == QLatin1String("dark"))
        return lookupPath(m_builtinDark, dottedPath);
    if (variant == QLatin1String("light"))
        return lookupPath(m_builtinLight, dottedPath);
    qWarning("theme: unknown variant \"%s\"", qPrintable(variant));
    return {};
}

bool ThemeManager::loadTheme(const QString &nameOrPath)
{
    QString error;
    const std::optional<Loaded> loaded = readTheme(nameOrPath, &error);
    if (!loaded) {
        qWarning("theme: cannot load \"%s\": %s", qPrintable(nameOrPath), qPrintable(error));
        return false;
    }
    apply(*loaded);
    return true;
}

void ThemeManager::reload()
{
    if (m_sourcePath.isEmpty()) {
        loadTheme(m_requestedVariant.isEmpty() ? QStringLiteral("dark") : m_requestedVariant);
        return;
    }
    QString error;
    const std::optional<Loaded> loaded = readTheme(m_sourcePath, &error);
    if (!loaded) {
        qWarning("theme: reload failed for %s: %s", qPrintable(m_sourcePath), qPrintable(error));
        const QString fallback = m_requestedVariant == QLatin1String("light") ? QStringLiteral("light")
                                                                               : QStringLiteral("dark");
        const QString fallbackPath = fallback == QLatin1String("light") ? QString::fromLatin1(kLightResource)
                                                                        : QString::fromLatin1(kDarkResource);
        if (m_sourcePath != fallbackPath)
            loadTheme(fallback);
        return;
    }
    apply(*loaded);
}

void ThemeManager::setVariant(const QString &variant)
{
    if (variant != QLatin1String("dark") && variant != QLatin1String("light")) {
        qWarning("theme: unknown variant \"%s\"", qPrintable(variant));
        return;
    }
    m_requestedVariant = variant;
    if (m_userTheme || m_currentTheme == variant)
        return;
    loadTheme(variant);
}

QUrl ThemeManager::overrideUrl(const QString &slot) const
{
    Q_UNUSED(slot);
    return {};
}

void ThemeManager::setHotReload(bool enabled)
{
    if (m_hotReload == enabled)
        return;
    m_hotReload = enabled;
    updateWatch();
    emit hotReloadChanged();
}

QString ThemeManager::locate(const QString &nameOrPath, QString *error) const
{
    QString text = nameOrPath.trimmed();
    if (text.startsWith(QLatin1String("qrc:")))
        text.remove(0, 3);
    if (text == QLatin1String("dark"))
        return QString::fromLatin1(kDarkResource);
    if (text == QLatin1String("light"))
        return QString::fromLatin1(kLightResource);

    const QFileInfo info(text);
    if (info.exists()) {
        if (info.isDir()) {
            const QString themeFile = info.filePath() + QStringLiteral("/theme.json");
            if (!QFile::exists(themeFile)) {
                *error = QStringLiteral("no theme.json in %1").arg(info.filePath());
                return {};
            }
            return themeFile;
        }
        return info.absoluteFilePath().startsWith(QLatin1Char(':')) ? text : info.absoluteFilePath();
    }
    if (text.startsWith(QLatin1Char(':')) || text.contains(QLatin1Char('/')) || text.contains(QLatin1Char('\\'))) {
        *error = QStringLiteral("theme file not found: %1").arg(text);
        return {};
    }

    QString nameError;
    const QString named = pathForThemeName(text, &nameError);
    if (named.isEmpty())
        *error = nameError;
    return named;
}

QString ThemeManager::pathForThemeName(const QString &name, QString *error) const
{
    if (name == QLatin1String("dark"))
        return QString::fromLatin1(kDarkResource);
    if (name == QLatin1String("light"))
        return QString::fromLatin1(kLightResource);

    const QDir dir(userThemesDirectory());
    if (dir.exists()) {
        const QFileInfoList entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const QFileInfo &info : entries) {
            QString path;
            QString fallback;
            if (info.isDir()) {
                path = info.filePath() + QStringLiteral("/theme.json");
                if (!QFile::exists(path))
                    continue;
                fallback = info.fileName();
            } else if (info.suffix().compare(QLatin1String("json"), Qt::CaseInsensitive) == 0) {
                path = info.absoluteFilePath();
                fallback = info.completeBaseName();
            } else {
                continue;
            }
            QString themeName = readThemeName(path);
            if (themeName.isEmpty())
                themeName = fallback;
            if (themeName == name)
                return path;
        }
    }
    *error = QStringLiteral("unknown theme \"%1\"").arg(name);
    return {};
}

QVariantMap ThemeManager::compose(const QString &path, QStringList *stack, QString *error) const
{
    if (stack->contains(path)) {
        *error = QStringLiteral("extends cycle at %1").arg(path);
        qWarning("theme: %s", qPrintable(*error));
        return {};
    }
    stack->append(path);

    QVariantMap doc = readObject(path, error);
    if (!error->isEmpty()) {
        stack->removeLast();
        return {};
    }
    if (!validateStructure(doc, path, error)) {
        stack->removeLast();
        return {};
    }
    if (doc.contains(QStringLiteral("extends"))) {
        const QString baseName = doc.take(QStringLiteral("extends")).toString();
        QString baseError;
        const QString basePath = pathForThemeName(baseName, &baseError);
        if (basePath.isEmpty()) {
            *error = baseError;
            qWarning("theme: %s (from %s)", qPrintable(baseError), qPrintable(path));
            stack->removeLast();
            return {};
        }
        const QVariantMap base = compose(basePath, stack, error);
        if (!error->isEmpty()) {
            stack->removeLast();
            return {};
        }
        doc = deepMerge(base, doc).toMap();
    }
    stack->removeLast();
    return doc;
}

std::optional<ThemeManager::Loaded> ThemeManager::readTheme(const QString &nameOrPath, QString *error) const
{
    const QString path = locate(nameOrPath, error);
    if (path.isEmpty())
        return std::nullopt;

    QStringList stack;
    QVariantMap merged = compose(path, &stack, error);
    if (!error->isEmpty())
        return std::nullopt;

    QString leafName = readThemeName(path);
    if (leafName.isEmpty())
        leafName = fallbackName(path);
    merged.insert(QStringLiteral("name"), leafName);

    QStringList refs;
    const QVariant resolved = resolveTree(merged, merged, &refs, QString(), path);
    const QVariant coerced = coerceTree(resolved, QString(), path);
    if (coerced.typeId() != QMetaType::QVariantMap) {
        *error = QStringLiteral("theme did not resolve to an object");
        qWarning("theme: %s (%s)", qPrintable(*error), qPrintable(path));
        return std::nullopt;
    }

    Loaded loaded;
    loaded.document = coerced.toMap();
    loaded.path = isBuiltinPath(path) ? path : QFileInfo(path).absoluteFilePath();
    loaded.name = loaded.document.value(QStringLiteral("name")).toString();
    loaded.variant = loaded.document.value(QStringLiteral("variant")).toString();
    loaded.user = !isBuiltinPath(loaded.path);
    return loaded;
}

void ThemeManager::apply(const Loaded &loaded)
{
    m_currentTheme = loaded.name;
    m_sourcePath = loaded.path;
    m_userTheme = loaded.user;
    m_resolved = loaded.document;
    if (loaded.path == QLatin1String(kDarkResource))
        m_builtinDark = loaded.document;
    else if (loaded.path == QLatin1String(kLightResource))
        m_builtinLight = loaded.document;

    QQmlPropertyMap *maps[] = {
        m_palette, m_semantic, m_components, m_metrics, m_typography, m_motion, m_window,
    };
    for (int i = 0; i < kGroups.size(); ++i)
        syncMap(maps[i], loaded.document.value(kGroups.at(i)).toMap());

    updateWatch();
    emit themeChanged();
    emit availableThemesChanged();
}

void ThemeManager::updateWatch()
{
    const QStringList watched = m_watcher.files();
    if (!watched.isEmpty())
        m_watcher.removePaths(watched);
    if (!m_hotReload || m_sourcePath.isEmpty() || m_sourcePath.startsWith(QLatin1Char(':')))
        return;
    if (QFile::exists(m_sourcePath))
        m_watcher.addPath(m_sourcePath);
}

void ThemeManager::onThemeFileChanged(const QString &path)
{
    if (!m_hotReload || m_inReload || path != m_sourcePath)
        return;
    m_inReload = true;
    reload();
    m_inReload = false;
}
