#pragma once

#include "engine/packages/looks/LookCatalog.h"

#include <QStringList>

namespace drift {

struct LookImportResult
{
    QStringList importedIds;
    QStringList errors; // "<file>: <reason>"
};

// Callers reload the look catalog afterwards.
LookImportResult importCubeFiles(const QStringList &paths, const QString &destRoot = userLooksDir());
bool removeUserLook(const QString &id, const QString &destRoot = userLooksDir());
bool renameUserLook(const QString &id, const QString &name, const QString &destRoot = userLooksDir());

} // namespace drift
