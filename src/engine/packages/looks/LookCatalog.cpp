#include "engine/packages/looks/LookCatalog.h"

#include "engine/addons/PackageSearchPaths.h"
#include "engine/color/CubeLut.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutex>
#include <QMutexLocker>
#include <QSet>
#include <QStandardPaths>

#include <algorithm>

namespace drift {
namespace {

QMutex g_mutex;
QList<LookEntry> g_looks;
bool g_initialized = false;

QString prettifyId(const QString &folder)
{
    QString text = folder;
    text.replace(QLatin1Char('_'), QLatin1Char(' '));
    text.replace(QLatin1Char('-'), QLatin1Char(' '));
    const QStringList words = text.simplified().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    QStringList titled;
    for (const QString &word : words)
        titled << word.at(0).toUpper() + word.mid(1).toLower();
    return titled.join(QLatin1Char(' '));
}

QStringList lookSearchPaths()
{
    QStringList roots = PackageSearchPaths::defaultSearchPaths(
        QStringLiteral("DRIFT_LOOKS_DIR"), QStringLiteral("looks"), QStringLiteral("looks"));
    roots.prepend(userLooksDir());
    roots.removeDuplicates();
    return roots;
}

void rebuildLocked(const QStringList &roots)
{
    g_looks.clear();
    g_initialized = true;

    const QStringList searchRoots = roots.isEmpty() ? lookSearchPaths() : roots;
    const QString userRoot = QDir::cleanPath(userLooksDir());
    QSet<QString> seenIds;

    for (const QString &root : searchRoots) {
        QDir dir(root);
        if (!dir.exists())
            continue;
        const bool userInstalled = QDir::cleanPath(dir.absolutePath()) == userRoot;

        for (const QFileInfo &subdir :
             dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name)) {
            const QString id = subdir.fileName();
            if (seenIds.contains(id))
                continue;
            const QDir look(subdir.absoluteFilePath());
            if (!QFileInfo::exists(look.filePath(QStringLiteral("look.cube"))))
                continue;
            seenIds.insert(id);

            LookEntry entry;
            entry.id = id;
            entry.label = prettifyId(id);
            entry.cubePath = look.filePath(QStringLiteral("look.cube"));
            entry.packageDir = look.absolutePath();
            entry.userInstalled = userInstalled;

            QFile manifest(look.filePath(QStringLiteral("look.json")));
            if (manifest.open(QIODevice::ReadOnly)) {
                const QJsonObject object = QJsonDocument::fromJson(manifest.readAll()).object();
                const QString name = object.value(QStringLiteral("name")).toString().trimmed();
                if (!name.isEmpty())
                    entry.label = name;
                entry.category = object.value(QStringLiteral("category")).toString().trimmed();
                entry.description = object.value(QStringLiteral("description")).toString();
                entry.order = object.value(QStringLiteral("order")).toInt();
            }

            g_looks.append(entry);
        }
    }

    std::stable_sort(g_looks.begin(), g_looks.end(), [](const LookEntry &a, const LookEntry &b) {
        const int byCategory = a.category.compare(b.category, Qt::CaseInsensitive);
        if (byCategory != 0)
            return byCategory < 0;
        if (a.order != b.order)
            return a.order < b.order;
        return a.label.compare(b.label, Qt::CaseInsensitive) < 0;
    });
}

void ensureLoadedLocked()
{
    if (!g_initialized)
        rebuildLocked({});
}

const bool g_resolverInstalled = [] {
    setLutResolver(&lookCubePathForId);
    return true;
}();

} // namespace

QString userLooksDir()
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("looks"));
}

QList<LookEntry> lookCatalog()
{
    QMutexLocker lock(&g_mutex);
    ensureLoadedLocked();
    return g_looks;
}

std::optional<LookEntry> lookForId(const QString &id)
{
    QMutexLocker lock(&g_mutex);
    ensureLoadedLocked();
    for (const LookEntry &entry : g_looks) {
        if (entry.id == id)
            return entry;
    }
    return std::nullopt;
}

void reloadLookCatalog(const QStringList &roots)
{
    QMutexLocker lock(&g_mutex);
    rebuildLocked(roots);
}

QString lookCubePathForId(const QString &id)
{
    QMutexLocker lock(&g_mutex);
    ensureLoadedLocked();
    for (const LookEntry &entry : g_looks) {
        if (entry.id == id)
            return entry.cubePath;
    }
    return {};
}

} // namespace drift
