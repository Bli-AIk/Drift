#include "engine/addons/PackageSearchPaths.h"

#include "engine/addons/AddonRegistry.h"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>

namespace PackageSearchPaths {

QStringList defaultSearchPaths(const QString &envVar, const QString &subdir,
                               const QString &addonKind)
{
    QStringList roots;

    const QByteArray env = qgetenv(envVar.toUtf8().constData());
    if (!env.isEmpty()) {
        const QStringList parts = QString::fromLocal8Bit(env).split(QDir::listSeparator(),
                                                                    Qt::SkipEmptyParts);
        roots.append(parts);
    }

    // Ahead of the bundled copy: effects and transitions ship with the build as a baseline, and an
    // installed addon of the same id is meant to supersede it.
    if (!addonKind.isEmpty())
        roots.append(drift::addon::addonRootsForKind(addonKind));

#if defined(Q_OS_ANDROID) || defined(Q_OS_WASM)
    // applicationDirPath() is the APK's lib directory and holds nothing but .so files, so the
    // bundled packages ride inside the binary as Qt resources instead (see qt_add_resources in
    // CMakeLists.txt). QDir enumerates and QFile reads ":/" paths exactly as real ones, which is
    // why every catalog and shader loader downstream works against them unchanged.
    roots.append(QStringLiteral(":/packages/") + subdir);
#else
    const QString appDir = QCoreApplication::applicationDirPath();
    if (!appDir.isEmpty()) {
        roots.append(QDir(appDir).filePath(subdir));
#ifdef Q_OS_MACOS
        // In a bundle applicationDirPath() is Contents/MacOS; packages ship in Contents/Resources.
        roots.append(QDir::cleanPath(QDir(appDir).filePath(QStringLiteral("../Resources/%1").arg(subdir))));
#endif
    }
#endif

    const QString appData = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!appData.isEmpty())
        roots.append(QDir(appData).filePath(subdir));

    roots.removeDuplicates();
    return roots;
}

} // namespace PackageSearchPaths
