#pragma once

#include "core/animation/Easing.h"

#include <QList>
#include <QMutex>
#include <QString>

#include <optional>

namespace drift {

struct UserEasingPreset
{
    QString id;
    QString label;
    EasingSpec spec;
};

// Easing curves the user saved from the curve editor. Persisted per-user (not per-project) as a
// single JSON file, the same way the effect and text preset libraries are.
class EasingPresetStore
{
public:
    static EasingPresetStore &instance();

    // By value: the library is read from QML while the GUI thread saves and deletes, so nothing
    // may hand out a pointer into it.
    QList<UserEasingPreset> all() const;
    std::optional<UserEasingPreset> find(const QString &id) const;

    // Returns the minted id, or an empty string when the label is blank or the save fails.
    QString add(const QString &label, const EasingSpec &spec);
    bool rename(const QString &id, const QString &label);
    bool remove(const QString &id);

    // Test seam: drops the in-memory copy so the next read re-reads the file.
    void reload();

    static QString storePath();

private:
    EasingPresetStore() = default;

    void ensureLoaded() const;  // call with m_mutex held
    bool save() const;          // call with m_mutex held

    mutable QMutex m_mutex;
    mutable QList<UserEasingPreset> m_presets;
    mutable bool m_loaded = false;
};

} // namespace drift
