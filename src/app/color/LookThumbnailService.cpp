#include "app/color/LookThumbnailService.h"

#include "core/project/Project.h"
#include "engine/compositor/FrameCompositor.h"
#include "ui/imageproviders/color/ColorImageProvider.h"

#include <QFutureWatcher>
#include <QTimer>
#include <QtConcurrent>

#include <algorithm>

namespace {

constexpr int kThumbnailWidth = 160;
constexpr int kDebounceMs = 300;

// Only the base frame is rendered here; ColorImageProvider applies each look to it when a card
// asks for its image, so a pack of hundreds of looks costs nothing until they scroll into view.
void renderLookBase(std::shared_ptr<const drift::Project> project, qint64 timeUs)
{
    FrameCompositor::RenderOptions options;
    options.previewScale = std::min(1.0, double(kThumbnailWidth) / qMax(1, project->width()));
    FrameCompositor compositor;
    compositor.setProject(project.get());
    const QImage base = compositor.compositeAt(timeUs, options).convertToFormat(QImage::Format_ARGB32);
    if (base.isNull())
        return;
    publishColorImage(QStringLiteral("look/none"), base);
}

} // namespace

LookThumbnailService::LookThumbnailService(std::function<drift::Project()> projectSnapshot, QObject *parent)
    : QObject(parent)
    , m_projectSnapshot(std::move(projectSnapshot))
    , m_debounce(new QTimer(this))
{
    m_debounce->setSingleShot(true);
    m_debounce->setInterval(kDebounceMs);
    connect(m_debounce, &QTimer::timeout, this, &LookThumbnailService::fire);
}

LookThumbnailService::~LookThumbnailService() = default;

void LookThumbnailService::request(qint64 timeUs, const QString &gradeHostClipId, int gradeEffectIndex)
{
    if (!m_active)
        return;
    m_timeUs = timeUs;
    m_gradeHostClipId = gradeHostClipId;
    m_gradeEffectIndex = gradeEffectIndex;
    m_debounce->start();
}

void LookThumbnailService::setActive(bool active)
{
    m_active = active;
    if (!active)
        m_debounce->stop();
}

void LookThumbnailService::fire()
{
    if (!m_active)
        return;
    if (m_rendering) {
        m_queued = true;
        return;
    }
    startRender();
}

void LookThumbnailService::startRender()
{
    m_rendering = true;
    const int serial = ++m_serial;

    drift::Project project = m_projectSnapshot();
    if (!m_gradeHostClipId.isEmpty()) {
        for (drift::Track &track : project.tracks()) {
            for (drift::Clip &clip : track.clips) {
                if (clip.id != m_gradeHostClipId)
                    continue;
                if (m_gradeEffectIndex >= 0 && m_gradeEffectIndex < clip.effects.size())
                    clip.effects[m_gradeEffectIndex].parameters.insert(QStringLiteral("look"), QString());
            }
        }
    }
    const auto snapshot = std::make_shared<const drift::Project>(std::move(project));

    auto *watcher = new QFutureWatcher<void>(this);
    connect(watcher, &QFutureWatcher<void>::finished, this, [this, watcher, serial]() {
        watcher->deleteLater();
        onRenderFinished(serial);
    });
    watcher->setFuture(QtConcurrent::run(renderLookBase, snapshot, m_timeUs));
}

void LookThumbnailService::onRenderFinished(int serial)
{
    m_rendering = false;
    emit thumbnailsReady(serial);
    if (m_queued) {
        m_queued = false;
        if (m_active)
            startRender();
    }
}
