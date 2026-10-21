#include "engine/packages/looks/LookImport.h"

#include "engine/color/CubeLut.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTemporaryDir>

namespace drift {
namespace {

constexpr auto kUserPrefix = "user.";

QString slugFor(const QString &stem)
{
    QString slug;
    bool pendingDash = false;
    for (const QChar ch : stem.toLower()) {
        const bool keep = (ch >= QLatin1Char('a') && ch <= QLatin1Char('z'))
            || (ch >= QLatin1Char('0') && ch <= QLatin1Char('9'));
        if (keep) {
            if (pendingDash && !slug.isEmpty())
                slug += QLatin1Char('-');
            pendingDash = false;
            slug += ch;
        } else {
            pendingDash = true;
        }
    }
    return slug.isEmpty() ? QStringLiteral("look") : slug;
}

QString uniqueUserId(const QString &slug, const QString &destRoot)
{
    QString id = QLatin1String(kUserPrefix) + slug;
    for (int n = 2; QFileInfo::exists(QDir(destRoot).filePath(id)); ++n)
        id = QLatin1String(kUserPrefix) + slug + QLatin1Char('-') + QString::number(n);
    return id;
}

bool writeManifest(const QString &path, const QJsonObject &object)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    return file.write(QJsonDocument(object).toJson(QJsonDocument::Indented)) >= 0;
}

bool isUserFolderName(const QString &id)
{
    return id.startsWith(QLatin1String(kUserPrefix)) && !id.contains(QLatin1Char('/'))
        && !id.contains(QLatin1Char('\\')) && id != QLatin1String(kUserPrefix);
}

} // namespace

LookImportResult importCubeFiles(const QStringList &paths, const QString &destRoot)
{
    LookImportResult result;
    QDir().mkpath(destRoot);

    for (const QString &path : paths) {
        const QFileInfo info(path);
        const QString stem = info.completeBaseName();

        CubeLut lut;
        QString error;
        if (!loadCubeFile(path, &lut, &error)) {
            result.errors << QStringLiteral("%1: %2").arg(info.fileName(), error);
            continue;
        }

        const QString id = uniqueUserId(slugFor(stem), destRoot);
        QTemporaryDir staging(QDir(destRoot).filePath(QStringLiteral(".importing-XXXXXX")));
        if (!staging.isValid()) {
            result.errors << QStringLiteral("%1: could not create a staging folder").arg(info.fileName());
            continue;
        }

        QJsonObject manifest;
        manifest.insert(QStringLiteral("name"), stem);
        manifest.insert(QStringLiteral("category"), QStringLiteral("My Looks"));
        if (!QFile::copy(path, QDir(staging.path()).filePath(QStringLiteral("look.cube")))
            || !writeManifest(QDir(staging.path()).filePath(QStringLiteral("look.json")), manifest)) {
            result.errors << QStringLiteral("%1: could not write the look").arg(info.fileName());
            continue;
        }

        if (!QDir().rename(staging.path(), QDir(destRoot).filePath(id))) {
            result.errors << QStringLiteral("%1: could not install the look").arg(info.fileName());
            continue;
        }
        result.importedIds << id;
    }

    return result;
}

bool removeUserLook(const QString &id, const QString &destRoot)
{
    if (!isUserFolderName(id))
        return false;
    return QDir(QDir(destRoot).filePath(id)).removeRecursively();
}

bool renameUserLook(const QString &id, const QString &name, const QString &destRoot)
{
    const QString trimmed = name.trimmed();
    if (!isUserFolderName(id) || trimmed.isEmpty())
        return false;

    const QDir look(QDir(destRoot).filePath(id));
    const QString manifestPath = look.filePath(QStringLiteral("look.json"));
    if (!QFileInfo::exists(look.filePath(QStringLiteral("look.cube"))))
        return false;

    QJsonObject manifest;
    QFile existing(manifestPath);
    if (existing.open(QIODevice::ReadOnly))
        manifest = QJsonDocument::fromJson(existing.readAll()).object();
    manifest.insert(QStringLiteral("name"), trimmed);
    return writeManifest(manifestPath, manifest);
}

} // namespace drift
