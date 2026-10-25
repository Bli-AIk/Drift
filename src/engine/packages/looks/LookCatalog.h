#pragma once

#include <QList>
#include <QString>
#include <QStringList>

#include <optional>

namespace drift {

// A color look: <root>/<id>/look.cube with an optional look.json next to it. The cube is only
// parsed when the look is applied, so a scan costs a directory listing per root.
struct LookEntry
{
    QString id;
    QString label;
    QString category;
    QString description;
    QString cubePath;
    QString packageDir;
    bool userInstalled = false;
    int order = 0;
};

QList<LookEntry> lookCatalog();
std::optional<LookEntry> lookForId(const QString &id);

void reloadLookCatalog(const QStringList &roots = {});

// Absolute path to the look's cube, or empty when the id is unknown. Safe from any thread, and
// loads the catalog on first use.
QString lookCubePathForId(const QString &id);

QString userLooksDir();

} // namespace drift
