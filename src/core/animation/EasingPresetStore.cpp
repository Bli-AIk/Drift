#include "core/animation/EasingPresetStore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QMutexLocker>
#include <QSaveFile>
#include <QStandardPaths>
#include <QUuid>

namespace drift {

namespace {

const QString kIdPrefix = QStringLiteral("user:");
constexpr int kLibraryVersion = 1;

QString mintId()
{
    return kIdPrefix + QUuid::createUuid().toString(QUuid::WithoutBraces);
}

} // namespace

EasingPresetStore &EasingPresetStore::instance()
{
    static EasingPresetStore store;
    return store;
}

QString EasingPresetStore::storePath()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (base.isEmpty())
        return {};
    return QDir(base).filePath(QStringLiteral("easing-presets.json"));
}

void EasingPresetStore::ensureLoaded() const
{
    if (m_loaded)
        return;
    m_loaded = true;
    m_presets.clear();

    const QString path = storePath();
    if (path.isEmpty())
        return;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return; // no library yet

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    for (const QJsonValue &value : root.value(QStringLiteral("presets")).toArray()) {
        const QJsonObject object = value.toObject();
        UserEasingPreset preset;
        preset.id = object.value(QStringLiteral("id")).toString();
        preset.label = object.value(QStringLiteral("label")).toString();
        preset.spec = EasingSpec::fromJson(object.value(QStringLiteral("spec")).toObject());
        if (!preset.id.startsWith(kIdPrefix) || preset.label.isEmpty())
            continue;
        m_presets.append(preset);
    }
}

bool EasingPresetStore::save() const
{
    const QString path = storePath();
    if (path.isEmpty())
        return false;

    QDir().mkpath(QFileInfo(path).absolutePath());

    QJsonArray presets;
    for (const UserEasingPreset &preset : m_presets) {
        presets.append(QJsonObject{
            {QStringLiteral("id"), preset.id},
            {QStringLiteral("label"), preset.label},
            {QStringLiteral("spec"), preset.spec.toJson()},
        });
    }

    const QJsonObject root{
        {QStringLiteral("version"), kLibraryVersion},
        {QStringLiteral("presets"), presets},
    };

    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    return file.commit();
}

QList<UserEasingPreset> EasingPresetStore::all() const
{
    QMutexLocker locker(&m_mutex);
    ensureLoaded();
    return m_presets;
}

std::optional<UserEasingPreset> EasingPresetStore::find(const QString &id) const
{
    QMutexLocker locker(&m_mutex);
    ensureLoaded();
    for (const UserEasingPreset &preset : m_presets) {
        if (preset.id == id)
            return preset;
    }
    return std::nullopt;
}

QString EasingPresetStore::add(const QString &label, const EasingSpec &spec)
{
    const QString trimmed = label.trimmed();
    if (trimmed.isEmpty())
        return {};

    QMutexLocker locker(&m_mutex);
    ensureLoaded();

    UserEasingPreset preset;
    preset.id = mintId();
    preset.label = trimmed;
    preset.spec = spec;

    m_presets.prepend(preset);
    if (!save()) {
        m_presets.removeFirst();
        return {};
    }
    return preset.id;
}

bool EasingPresetStore::rename(const QString &id, const QString &label)
{
    const QString trimmed = label.trimmed();
    if (trimmed.isEmpty())
        return false;

    QMutexLocker locker(&m_mutex);
    ensureLoaded();
    for (UserEasingPreset &preset : m_presets) {
        if (preset.id != id)
            continue;
        const QString previous = preset.label;
        preset.label = trimmed;
        if (!save()) {
            preset.label = previous;
            return false;
        }
        return true;
    }
    return false;
}

bool EasingPresetStore::remove(const QString &id)
{
    QMutexLocker locker(&m_mutex);
    ensureLoaded();
    for (int i = 0; i < m_presets.size(); ++i) {
        if (m_presets.at(i).id != id)
            continue;
        const UserEasingPreset removed = m_presets.takeAt(i);
        if (!save()) {
            m_presets.insert(i, removed);
            return false;
        }
        return true;
    }
    return false;
}

void EasingPresetStore::reload()
{
    QMutexLocker locker(&m_mutex);
    m_loaded = false;
    m_presets.clear();
}

} // namespace drift
