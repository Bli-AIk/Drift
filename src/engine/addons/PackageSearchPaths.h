#pragma once

#include <QString>
#include <QStringList>

namespace PackageSearchPaths {

// Search roots for a package kind, highest priority first:
//
//   1. $<envVar>                      a developer override, always wins
//   2. installed addons of addonKind  downloaded updates (empty addonKind to skip)
//   3. <appDir>/<subdir>              content bundled with the build, if any
//   4. <AppDataLocation>/<subdir>     hand-placed content
//
// Every catalog resolves duplicate ids by first-root-wins, so this ordering is what lets an
// addon update replace a bundled package of the same id without touching the install.
QStringList defaultSearchPaths(const QString &envVar, const QString &subdir,
                               const QString &addonKind = {});

} // namespace PackageSearchPaths
