#include "app/color/ColorController.h"

#include "app/color/LookThumbnailService.h"
#include "app/color/ScopesController.h"
#include "app/editor/AppController.h"
#include "app/mcp/McpDetail.h"
#include "core/effects/Effect.h"
#include "core/project/Project.h"
#include "engine/color/CubeLut.h"
#include "engine/packages/effects/EffectCatalog.h"
#include "engine/packages/looks/LookCatalog.h"
#include "engine/packages/looks/LookImport.h"
#include "playback/PlaybackEngine.h"

#include <QSet>
#include <QStringList>
#include <QtConcurrent>

namespace {

const QString kGradeId = QStringLiteral("color.grade");
const QStringList kFinishingIds = {
    QStringLiteral("film_grain"),
    QStringLiteral("bloom_glow"),
    QStringLiteral("chromatic_aberration"),
    QStringLiteral("stylize.vignette"),
    QStringLiteral("halation"),
};

bool isVisualClip(const drift::Clip &clip)
{
    switch (clip.type) {
    case drift::ClipType::Video:
    case drift::ClipType::Image:
    case drift::ClipType::Text:
    case drift::ClipType::Shape:
    case drift::ClipType::Vector:
    case drift::ClipType::Model3d:
    case drift::ClipType::Pdf:
    case drift::ClipType::Composite:
        return true;
    default:
        return false;
    }
}

bool isGradable(const drift::Clip &clip)
{
    if (clip.type == drift::ClipType::Adjustment)
        return clip.adjustmentKind == drift::AdjustmentKind::VideoEffects;
    return isVisualClip(clip);
}

int effectIndexOf(const drift::Clip *host, const QString &catalogId)
{
    if (!host)
        return -1;
    for (int i = 0; i < host->effects.size(); ++i) {
        if (host->effects.at(i).catalogId == catalogId)
            return i;
    }
    return -1;
}

bool keyed(const drift::Effect &effect, const QString &trackKey)
{
    const auto it = effect.paramKeyframes.constFind(trackKey);
    return it != effect.paramKeyframes.constEnd() && !it->isEmpty();
}

QStringList animatedKeysOf(const drift::Effect *effect, const EffectPresetEntry &def)
{
    QStringList keys;
    if (!effect)
        return keys;
    for (const drift::EffectParamSpec &spec : def.meta.parameters) {
        const bool animated = spec.isVec2()
                                  ? keyed(*effect, spec.key + QStringLiteral(".x"))
                                        || keyed(*effect, spec.key + QStringLiteral(".y"))
                                  : keyed(*effect, spec.key);
        if (animated)
            keys.append(spec.key);
    }
    return keys;
}

QVariantMap paramValuesOf(const drift::Effect *effect, const EffectPresetEntry &def)
{
    QVariantMap values;
    for (const drift::EffectParamSpec &spec : def.meta.parameters) {
        if (spec.isVec2()) {
            const double x = effect ? effect->parameters.value(spec.key + QStringLiteral(".x"), spec.defaultX).toDouble()
                                    : spec.defaultX;
            const double y = effect ? effect->parameters.value(spec.key + QStringLiteral(".y"), spec.defaultY).toDouble()
                                    : spec.defaultY;
            values.insert(spec.key, QVariantList{x, y});
        } else {
            const QVariant value = effect ? effect->parameters.value(spec.key) : QVariant();
            values.insert(spec.key, value.isValid() ? value : spec.defaultVariant());
        }
    }
    return values;
}

drift::Effect effectFromCatalog(const EffectPresetEntry &def)
{
    drift::Effect effect;
    effect.name = def.filterName;
    effect.catalogId = def.meta.id;
    for (auto it = def.fixedParams.constBegin(); it != def.fixedParams.constEnd(); ++it)
        effect.parameters.insert(it.key(), it.value());
    for (const drift::EffectParamSpec &p : def.meta.parameters)
        p.insertDefault(effect.parameters);
    return effect;
}

} // namespace

ColorController::ColorController(AppController *app, QObject *parent)
    : QObject(parent)
    , m_app(app)
{
    // Runs on the GUI thread at render time, so the copy is taken from the live project.
    m_thumbs = new LookThumbnailService([app]() { return app->m_project.detachedCopy(); }, this);
    m_scopes = new ScopesController(app, this);
    connect(m_thumbs, &LookThumbnailService::thumbnailsReady, this, [this](int serial) {
        m_thumbnailSerial = serial;
        emit thumbnailSerialChanged();
    });
    connect(app, &AppController::selectedClipDataChanged, this, &ColorController::refreshTarget);
    connect(app, &AppController::tracksChanged, this, &ColorController::refreshTarget);
    connect(app, &AppController::undoStackChanged, this, &ColorController::refreshTarget);
    connect(app, &AppController::playheadSecondsChanged, this, [this]() {
        if (m_thumbnailsActive && !m_app->playing())
            requestThumbnails();
    });
    rebuildLooks();
    refreshTarget();
}

// ---- Lookup ------------------------------------------------------------------------------

bool ColorController::locate(const QString &clipId, int *trackIndex, int *clipIndex) const
{
    return !clipId.isEmpty()
           && drift::mcpdetail::findClipById(m_app->m_project, clipId, trackIndex, clipIndex);
}

QString ColorController::hostIdFor(const QString &clipId) const
{
    int t = -1;
    int c = -1;
    if (!locate(clipId, &t, &c))
        return {};
    const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    return host ? host->id : QString();
}

QVariantMap ColorController::buildTarget() const
{
    int t = -1;
    int c = -1;
    const bool found = locate(m_sourceClipId, &t, &c);
    const drift::Clip *source = found ? &m_app->m_project.tracks().at(t).clips.at(c) : nullptr;
    const bool gradable = source && isGradable(*source);
    const drift::Clip *host = gradable ? m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects) : nullptr;
    const int gradeIndex = effectIndexOf(host, kGradeId);
    const drift::Effect *grade = gradeIndex >= 0 ? &host->effects.at(gradeIndex) : nullptr;

    QVariantMap out;
    out.insert(QStringLiteral("hasTarget"), gradable);
    out.insert(QStringLiteral("label"), source ? source->name : QString());
    out.insert(QStringLiteral("sourceClipId"), m_sourceClipId);
    out.insert(QStringLiteral("hasGrade"), grade != nullptr);
    out.insert(QStringLiteral("gradeIndex"), gradeIndex);
    if (const EffectPresetEntry *def = effectDefForId(kGradeId)) {
        out.insert(QStringLiteral("params"), paramValuesOf(grade, *def));
        out.insert(QStringLiteral("animatedKeys"), animatedKeysOf(grade, *def));
    }

    QVariantList finishing;
    for (const QString &id : kFinishingIds) {
        const EffectPresetEntry *def = effectDefForId(id);
        if (!def)
            continue;
        const int index = effectIndexOf(host, id);
        const drift::Effect *effect = index >= 0 ? &host->effects.at(index) : nullptr;
        QVariantMap entry;
        entry.insert(QStringLiteral("id"), id);
        entry.insert(QStringLiteral("label"), def->meta.displayName);
        entry.insert(QStringLiteral("present"), effect != nullptr);
        entry.insert(QStringLiteral("index"), index);
        entry.insert(QStringLiteral("enabled"), effect ? effect->enabled : false);
        entry.insert(QStringLiteral("params"), paramValuesOf(effect, *def));
        entry.insert(QStringLiteral("animatedKeys"), animatedKeysOf(effect, *def));
        finishing.append(entry);
    }
    out.insert(QStringLiteral("finishing"), finishing);
    return out;
}

void ColorController::refreshTarget()
{
    QString selected;
    const drift::Project &project = m_app->m_project;
    if (m_app->m_selectedTrack >= 0 && m_app->m_selectedTrack < project.tracks().size()) {
        const drift::Track &track = project.tracks().at(m_app->m_selectedTrack);
        if (m_app->m_selectedClip >= 0 && m_app->m_selectedClip < track.clips.size())
            selected = track.clips.at(m_app->m_selectedClip).id;
    }
    m_sourceClipId = selected;

    QVariantMap next = buildTarget();
    if (next != m_target) {
        m_target = next;
        emit targetChanged();
    }
    applyBypass();
    requestThumbnails();
}

void ColorController::rebuildLooks()
{
    QVariantList list;
    list.append(QVariantMap{{QStringLiteral("id"), QString()},
                            {QStringLiteral("label"), tr("None")},
                            {QStringLiteral("category"), QString()},
                            {QStringLiteral("userInstalled"), false}});
    for (const drift::LookEntry &look : drift::lookCatalog()) {
        list.append(QVariantMap{{QStringLiteral("id"), look.id},
                                {QStringLiteral("label"), look.label},
                                {QStringLiteral("category"), look.category},
                                {QStringLiteral("userInstalled"), look.userInstalled}});
    }
    m_looks = list;
    emit looksChanged();
}

// ---- Edits -------------------------------------------------------------------------------

bool ColorController::editTarget(int *trackIndex, int *clipIndex) const
{
    return m_editEffectIndex >= 0 && locate(m_editHostId, trackIndex, clipIndex);
}

bool ColorController::editKeyed(const QString &trackKey) const
{
    int t = -1;
    int c = -1;
    if (!editTarget(&t, &c))
        return false;
    const drift::Clip &host = m_app->m_project.tracks().at(t).clips.at(c);
    return m_editEffectIndex < host.effects.size()
           && keyed(host.effects.at(m_editEffectIndex), trackKey);
}

void ColorController::writeParam(const QString &key, double v)
{
    int t = -1;
    int c = -1;
    if (!editTarget(&t, &c))
        return;
    if (editKeyed(key)) {
        m_app->previewSetClipKeyframe(t, c, QStringLiteral("fx.%1.%2").arg(m_editEffectIndex).arg(key),
                                      m_app->playheadSeconds(), v);
        return;
    }
    m_app->previewSetEffectParam(t, c, m_editEffectIndex, key, v);
}

void ColorController::writeVec2(const QString &key, double x, double y)
{
    int t = -1;
    int c = -1;
    if (!editTarget(&t, &c))
        return;
    if (editKeyed(key + QStringLiteral(".x")) || editKeyed(key + QStringLiteral(".y"))) {
        const double at = m_app->playheadSeconds();
        m_app->previewSetClipKeyframe(t, c, QStringLiteral("fx.%1.%2.x").arg(m_editEffectIndex).arg(key), at, x);
        m_app->previewSetClipKeyframe(t, c, QStringLiteral("fx.%1.%2.y").arg(m_editEffectIndex).arg(key), at, y);
        return;
    }
    m_app->previewSetEffectVec2Param(t, c, m_editEffectIndex, key, x, y);
}

void ColorController::writeText(const QString &key, const QString &value)
{
    int t = -1;
    int c = -1;
    if (editTarget(&t, &c))
        m_app->previewSetEffectTextParam(t, c, m_editEffectIndex, key, value);
}

void ColorController::beginEdit(const QString &label)
{
    if (m_editing)
        return;
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c) || !isGradable(m_app->m_project.tracks().at(t).clips.at(c)))
        return;
    const EffectPresetEntry *def = effectDefForId(kGradeId);
    if (!def)
        return;

    // Begin before anything is created: beginPreviewDrag snapshots the project now, and creating
    // the host inserts a track, so this makes the grade's creation part of the same undo step.
    m_app->beginPreviewDrag(label);
    if (!locate(m_sourceClipId, &t, &c)) {
        m_app->cancelPreviewDrag();
        return;
    }
    const drift::ClipRef ref = m_app->effectHostRef(t, c, drift::AdjustmentKind::VideoEffects, /*create=*/true);
    if (ref.trackIndex < 0) {
        m_app->cancelPreviewDrag();
        return;
    }
    drift::Clip &host = m_app->m_project.tracks()[ref.trackIndex].clips[ref.clipIndex];
    int index = effectIndexOf(&host, kGradeId);
    const bool created = index < 0;
    if (created) {
        host.effects.append(effectFromCatalog(*def));
        index = host.effects.size() - 1;
    }

    m_editing = true;
    m_editHostId = host.id;
    m_editCatalogId = kGradeId;
    m_editEffectIndex = index;
    if (created) {
        // A drag that writes nothing commits nothing, so the grade created above would be left
        // with no undo step. Writing back the value it already has marks the drag as dirty.
        writeParam(QStringLiteral("exposure"), host.effects.at(index).parameters.value(QStringLiteral("exposure")).toDouble());
    }
}

void ColorController::beginFinishingEdit(const QString &id, const QString &label)
{
    if (m_editing)
        return;
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return;
    const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    const int index = effectIndexOf(host, id);
    if (index < 0)
        return;
    const QString hostId = host->id;

    m_app->beginPreviewDrag(label);
    m_editing = true;
    m_editHostId = hostId;
    m_editCatalogId = id;
    m_editEffectIndex = index;
}

void ColorController::commitEdit()
{
    if (!m_editing)
        return;
    m_editing = false;
    m_editHostId.clear();
    m_editCatalogId.clear();
    m_editEffectIndex = -1;
    m_app->commitPreviewDrag();
    requestThumbnails();
}

void ColorController::cancelEdit()
{
    if (!m_editing)
        return;
    m_editing = false;
    m_editHostId.clear();
    m_editCatalogId.clear();
    m_editEffectIndex = -1;
    m_app->cancelPreviewDrag();
}

void ColorController::setParam(const QString &key, double v)
{
    const bool implicit = !m_editing;
    if (implicit)
        beginEdit(tr("Adjust color"));
    writeParam(key, v);
    if (implicit)
        commitEdit();
}

void ColorController::setVec2(const QString &key, double x, double y)
{
    const bool implicit = !m_editing;
    if (implicit)
        beginEdit(tr("Adjust color"));
    writeVec2(key, x, y);
    if (implicit)
        commitEdit();
}

void ColorController::setText(const QString &key, const QString &s)
{
    const bool implicit = !m_editing;
    if (implicit)
        beginEdit(tr("Adjust color"));
    writeText(key, s);
    if (implicit)
        commitEdit();
}

void ColorController::setLook(const QString &id)
{
    const bool implicit = !m_editing;
    if (implicit)
        beginEdit(tr("Set look"));
    writeText(QStringLiteral("look"), id);
    if (implicit)
        commitEdit();
    if (!id.isEmpty())
        (void)QtConcurrent::run([id]() { drift::bakedLutForId(id); });
}

void ColorController::resetParams(const QString &group, const QString &undoText)
{
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return;
    const EffectPresetEntry *def = effectDefForId(kGradeId);
    if (!def)
        return;

    const drift::Project before = m_app->m_project;
    const drift::ClipRef ref = m_app->effectHostRef(t, c, drift::AdjustmentKind::VideoEffects, /*create=*/false);
    if (ref.trackIndex < 0)
        return;
    drift::Clip &host = m_app->m_project.tracks()[ref.trackIndex].clips[ref.clipIndex];
    const int index = effectIndexOf(&host, kGradeId);
    if (index < 0)
        return;

    drift::Effect &grade = host.effects[index];
    for (const drift::EffectParamSpec &spec : def->meta.parameters) {
        if (!group.isEmpty() && spec.group != group)
            continue;
        spec.insertDefault(grade.parameters);
        for (const QString &trackKey : {spec.key, spec.key + QStringLiteral(".x"), spec.key + QStringLiteral(".y")})
            grade.paramKeyframes.remove(trackKey);
    }
    m_app->pushProjectEdit(before, undoText);
    m_app->finishEdit(undoText);
}

void ColorController::resetGroup(const QString &group)
{
    resetParams(group, tr("Reset %1").arg(group));
}

void ColorController::resetAll()
{
    resetParams(QString(), tr("Reset grade"));
}

// ---- Looks -------------------------------------------------------------------------------

void ColorController::importLooks(const QList<QUrl> &urls)
{
    QStringList paths;
    for (const QUrl &url : urls) {
        if (url.isLocalFile())
            paths.append(url.toLocalFile());
    }
    if (paths.isEmpty())
        return;

    const drift::LookImportResult result = drift::importCubeFiles(paths);
    drift::reloadLookCatalog();
    rebuildLooks();
    const int imported = result.importedIds.size();
    const int failed = result.errors.size();
    if (failed == 0)
        m_app->setLastMessage(tr("Imported %n look(s)", "", imported), QStringLiteral("success"));
    else
        m_app->setLastMessage(tr("Imported %n look(s), %1 failed", "", imported).arg(failed),
                              QStringLiteral("warning"));
}

void ColorController::removeLook(const QString &id)
{
    if (!drift::removeUserLook(id)) {
        m_app->setLastMessage(tr("Could not remove the look"), QStringLiteral("error"));
        return;
    }
    drift::reloadLookCatalog();
    rebuildLooks();
    m_app->setLastMessage(tr("Look removed"), QStringLiteral("success"));
}

void ColorController::renameLook(const QString &id, const QString &name)
{
    if (!drift::renameUserLook(id, name)) {
        m_app->setLastMessage(tr("Could not rename the look"), QStringLiteral("error"));
        return;
    }
    drift::reloadLookCatalog();
    rebuildLooks();
    m_app->setLastMessage(tr("Look renamed"), QStringLiteral("success"));
}

void ColorController::refreshForKind(const QString &kind)
{
    if (kind != QLatin1String("looks"))
        return;
    drift::reloadLookCatalog();
    rebuildLooks();
}

// ---- Finishing ---------------------------------------------------------------------------

QVariantList ColorController::finishingCatalog() const
{
    QVariantList list;
    for (const QString &id : kFinishingIds) {
        if (const EffectPresetEntry *def = effectDefForId(id))
            list.append(QVariantMap{{QStringLiteral("id"), id}, {QStringLiteral("label"), def->meta.displayName}});
    }
    return list;
}

QVariantList ColorController::finishingParamSpecs(const QString &id) const
{
    QVariantList list;
    const EffectPresetEntry *def = kFinishingIds.contains(id) ? effectDefForId(id) : nullptr;
    if (!def)
        return list;
    for (const drift::EffectParamSpec &spec : def->meta.parameters) {
        list.append(QVariantMap{{QStringLiteral("key"), spec.key},
                                {QStringLiteral("label"), spec.label},
                                {QStringLiteral("type"), spec.typeName()},
                                {QStringLiteral("min"), spec.min},
                                {QStringLiteral("max"), spec.max},
                                {QStringLiteral("default"), spec.isColor() ? QVariant(spec.defaultColorHex) : spec.defaultVariant()},
                                {QStringLiteral("step"), spec.step},
                                {QStringLiteral("group"), spec.group}});
    }
    return list;
}

void ColorController::toggleFinishing(const QString &id, bool on)
{
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return;
    if (!isGradable(m_app->m_project.tracks().at(t).clips.at(c)))
        return;
    const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    const int index = effectIndexOf(host, id);
    if (on) {
        if (index < 0)
            m_app->addEffect(t, c, id);
    } else if (index >= 0) {
        m_app->removeEffect(t, c, index);
    }
}

void ColorController::setFinishingEnabled(const QString &id, bool enabled)
{
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return;
    const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    const int index = effectIndexOf(host, id);
    if (index >= 0)
        m_app->setEffectEnabled(t, c, index, enabled);
}

void ColorController::setFinishingParam(const QString &id, const QString &key, double v)
{
    const EffectPresetEntry *def = effectDefForId(id);
    if (!def)
        return;
    const bool implicit = !m_editing;
    if (implicit)
        beginFinishingEdit(id, def->meta.displayName);
    if (m_editing && m_editCatalogId == id)
        writeParam(key, v);
    if (implicit)
        commitEdit();
}

void ColorController::setFinishingColor(const QString &id, const QString &key, const QString &hex)
{
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return;
    const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    const int index = effectIndexOf(host, id);
    if (index >= 0)
        m_app->setEffectColorParam(t, c, index, key, hex);
}

// ---- Whole-project ---------------------------------------------------------------------

int ColorController::applyToAll(bool includeFinishing)
{
    int t = -1;
    int c = -1;
    if (!locate(m_sourceClipId, &t, &c))
        return 0;
    const drift::Clip *sourceHost = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
    const int gradeIndex = effectIndexOf(sourceHost, kGradeId);
    if (gradeIndex < 0) {
        m_app->setLastMessage(tr("Grade this clip before applying it to others"), QStringLiteral("warning"));
        return 0;
    }
    // Copied now: creating a host for another clip inserts tracks and moves the source host.
    const drift::Effect grade = sourceHost->effects.at(gradeIndex);
    const drift::TimeUs sourceSpan = sourceHost->timelineDuration;
    QList<drift::Effect> finishing;
    if (includeFinishing) {
        for (const QString &id : kFinishingIds) {
            const int index = effectIndexOf(sourceHost, id);
            if (index >= 0)
                finishing.append(sourceHost->effects.at(index));
        }
    }

    QStringList targets;
    for (const drift::Track &track : m_app->m_project.tracks()) {
        for (const drift::Clip &clip : track.clips) {
            if (clip.id != m_sourceClipId && isVisualClip(clip))
                targets.append(clip.id);
        }
    }
    if (targets.isEmpty()) {
        m_app->setLastMessage(tr("No other clips to apply the grade to"), QStringLiteral("warning"));
        return 0;
    }

    const drift::Project before = m_app->m_project;
    int applied = 0;
    for (const QString &targetId : targets) {
        int targetTrack = -1;
        int targetClip = -1;
        if (!locate(targetId, &targetTrack, &targetClip))
            continue;
        const drift::ClipRef ref = m_app->effectHostRef(targetTrack, targetClip,
                                                        drift::AdjustmentKind::VideoEffects, /*create=*/true);
        if (ref.trackIndex < 0)
            continue;
        drift::Clip &host = m_app->m_project.tracks()[ref.trackIndex].clips[ref.clipIndex];
        for (int i = host.effects.size() - 1; i >= 0; --i) {
            if (host.effects.at(i).catalogId == kGradeId)
                host.effects.removeAt(i);
        }

        QList<drift::Effect> additions{grade};
        for (const drift::Effect &fin : finishing) {
            if (effectIndexOf(&host, fin.catalogId) < 0)
                additions.append(fin);
        }
        drift::rescaleEffectKeyframes(additions, sourceSpan, host.timelineDuration);
        for (const drift::Effect &effect : additions)
            host.effects.append(effect);
        ++applied;
    }
    if (applied == 0)
        return 0;

    m_app->pushProjectEdit(before, tr("Apply grade to all clips"));
    m_app->finishEdit(tr("Grade applied to %n clip(s)", "", applied));
    return applied;
}

void ColorController::gradeWholeTimeline()
{
    m_app->addAdjustmentClipWithEffect(kGradeId, -1, 0.0, m_app->durationSeconds());
}

// ---- Bypass and thumbnails -------------------------------------------------------------

void ColorController::setBypass(bool on)
{
    if (m_bypass == on)
        return;
    m_bypass = on;
    emit bypassChanged();
    applyBypass();
}

void ColorController::applyBypass()
{
    // Preview only: the bypass lives in the compositor's snapshot, so nothing here is undoable
    // and the project is not dirtied.
    const QString hostId = m_bypass ? hostIdFor(m_sourceClipId) : QString();
    if (hostId == m_bypassedHostId)
        return;
    m_bypassedHostId = hostId;

    QSet<QString> clipIds;
    QSet<QString> catalogIds;
    if (!hostId.isEmpty()) {
        clipIds.insert(hostId);
        catalogIds.insert(kGradeId);
        for (const QString &id : kFinishingIds)
            catalogIds.insert(id);
    }
    m_app->playback()->setPreviewEffectBypass(clipIds, catalogIds);
}

void ColorController::setThumbnailsActive(bool active)
{
    if (m_thumbnailsActive == active)
        return;
    m_thumbnailsActive = active;
    m_thumbs->setActive(active);
    emit thumbnailsActiveChanged();
    requestThumbnails();
}

void ColorController::requestThumbnails()
{
    if (!m_thumbnailsActive)
        return;
    int t = -1;
    int c = -1;
    QString hostId;
    int gradeIndex = -1;
    if (locate(m_sourceClipId, &t, &c)) {
        const drift::Clip *host = m_app->effectHostClip(t, c, drift::AdjustmentKind::VideoEffects);
        gradeIndex = effectIndexOf(host, kGradeId);
        if (gradeIndex >= 0)
            hostId = host->id;
    }
    m_thumbs->request(m_app->playheadUs(), hostId, gradeIndex);
}
