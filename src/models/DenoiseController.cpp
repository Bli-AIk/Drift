#include "DenoiseController.h"

#include "AppController.h"
#include "engine/AudioFileWriter.h"
#include "engine/ClipReaderPool.h"
#include "engine/DeepFilterDenoiser.h"

#include <QFile>
#include <QMetaObject>
#include <QtConcurrent>
#include <QUuid>

#include <algorithm>

DenoiseController::DenoiseController(AppController *app, QObject *parent)
    : QObject(parent)
    , m_app(app)
{
}

namespace {

constexpr quint64 kDenoiseScanStreamId = 0xA5'11'5C'A4'00'00'00'02ull;

} // namespace

// ---- Noise removal ----------------------------------------------------------------------

bool DenoiseController::available()
{
    // Deliberately only checks that the model files exist. This is reached from a QML binding, and
    // loading the session here would block the GUI thread.
    return drift::DeepFilterDenoiser::modelPresent();
}

void DenoiseController::cancel()
{
    if (m_running)
        m_cancel.storeRelaxed(1);
}

bool DenoiseController::renderAudio(const QString &path, drift::TimeUs srcIn,
                                    drift::TimeUs span, const QString &outPath,
                                    const QString &originalPath, double progressFrom,
                                    double progressTo, QString *errorOut)
{
    const auto fail = [&](const QString &message) {
        if (errorOut)
            *errorOut = message;
        return false;
    };
    const auto setProgress = [this](double fraction, const QString &status) {
        QMetaObject::invokeMethod(
            this,
            [this, fraction, status]() {
                m_progress = fraction;
                emit progressChanged();
                if (!status.isEmpty() && status != m_status) {
                    m_status = status;
                    emit statusChanged();
                }
            },
            Qt::QueuedConnection);
    };
    const auto span01 = [progressFrom, progressTo](double f) {
        return progressFrom + (progressTo - progressFrom) * std::clamp(f, 0.0, 1.0);
    };

    drift::DeepFilterDenoiser &dn = drift::DeepFilterDenoiser::instance();
    setProgress(span01(0.0), tr("Getting noise removal ready…"));
    if (!dn.available())
        return fail(dn.lastError());

    const int rate = drift::DeepFilterDenoiser::sampleRate();
    const int64_t totalFrames = (span * rate) / drift::kUsPerSecond;
    if (totalFrames <= 0)
        return fail(tr("Clip is too short to process"));

    // Decode the raw source window. Speed and reverse are deliberately not applied: the derived
    // clip inherits them, so the render has to stay in the source's own time base.
    setProgress(span01(0.05), tr("Reading audio…"));
    std::vector<float> interleaved(size_t(totalFrames) * 2, 0.0f);
    int64_t have = 0;
    const int chunkFrames = rate * 10;
    while (have < totalFrames) {
        if (m_cancel.loadRelaxed())
            return fail(tr("Noise removal cancelled"));
        const drift::TimeUs at = srcIn + drift::TimeUs((have * drift::kUsPerSecond) / rate);
        const int want = int(std::min<int64_t>(chunkFrames, totalFrames - have));
        const int got = ClipReaderPool::instance().readAudioInterleaved(
            path, kDenoiseScanStreamId, at, want, rate, interleaved.data() + size_t(have) * 2);
        if (got <= 0)
            break;
        have += got;
        setProgress(span01(0.05 + 0.20 * double(have) / double(totalFrames)),
                    tr("Reading audio…"));
    }
    if (have <= 0)
        return fail(tr("No audio decoded"));
    interleaved.resize(size_t(have) * 2);

    // The A/B source for the preview window, written before the model runs so a cancel still
    // leaves nothing half-made.
    if (!originalPath.isEmpty()) {
        drift::AudioFileWriter orig;
        QString error;
        if (!orig.open(originalPath, rate, 2, &error))
            return fail(error);
        if (!orig.writeFrames(interleaved.data(), int(have), &error) || !orig.finish(&error)) {
            orig.abort();
            return fail(error);
        }
    }

    // The model is mono, so each channel goes through separately and the stereo image is kept.
    std::vector<float> mono(size_t(have), 0.0f);
    for (int ch = 0; ch < 2; ++ch) {
        for (int64_t i = 0; i < have; ++i)
            mono[size_t(i)] = interleaved[size_t(i) * 2 + ch];

        const double base = 0.25 + 0.35 * ch;
        const std::vector<float> clean = dn.denoise(mono, [&](double f) {
            setProgress(span01(base + 0.35 * f),
                        ch == 0 ? tr("Removing noise (left)…")
                                : tr("Removing noise (right)…"));
            return m_cancel.loadRelaxed() == 0;
        });
        if (clean.empty()) {
            return fail(m_cancel.loadRelaxed() ? tr("Noise removal cancelled")
                                                      : dn.lastError());
        }
        for (int64_t i = 0; i < have; ++i)
            interleaved[size_t(i) * 2 + ch] = clean[size_t(i)];
    }

    setProgress(span01(0.95), tr("Writing audio…"));
    drift::AudioFileWriter writer;
    QString error;
    if (!writer.open(outPath, rate, 2, &error))
        return fail(error);
    if (!writer.writeFrames(interleaved.data(), int(have), &error) || !writer.finish(&error)) {
        writer.abort();
        return fail(error);
    }

    setProgress(span01(1.0), QString());
    return true;
}

// Both entry points share this: validate the clip, latch the busy state, and hand the work to a
// pool thread. `preview` bounds the render to a short window and reports the pair of files rather
// than touching the project.
void DenoiseController::preview(int trackIndex, int clipIndex, double atSeconds)
{
    if (m_running) {
        m_app->setLastMessage(tr("Noise removal already in progress"), QStringLiteral("warning"));
        return;
    }
    if (trackIndex < 0 || trackIndex >= m_app->m_project.tracks().size())
        return;
    const drift::Track &track = m_app->m_project.tracks().at(trackIndex);
    if (clipIndex < 0 || clipIndex >= track.clips.size())
        return;

    const drift::Clip clip = track.clips.at(clipIndex);
    if (clip.type != drift::ClipType::Audio && clip.type != drift::ClipType::Video) {
        m_app->setLastMessage(tr("Select a video or audio clip"), QStringLiteral("warning"));
        return;
    }
    if (clip.path.isEmpty() || clip.srcOut <= clip.srcIn) {
        m_app->setLastMessage(tr("Clip has no audio"), QStringLiteral("warning"));
        return;
    }

    // Same reason as the export, subtitle and segmentation jobs: playback would drive the decode
    // pool from a second thread while this walks it.
    m_app->setPlaying(false);

    // Eight seconds is enough to judge the result and short enough that dragging the window along
    // the clip stays responsive.
    constexpr drift::TimeUs kPreviewSpan = 8 * drift::kUsPerSecond;
    const drift::TimeUs clipSpan = clip.srcOut - clip.srcIn;
    const drift::TimeUs offset =
        qBound<drift::TimeUs>(0, drift::secondsToUs(atSeconds) * clip.effectiveSpeed(),
                              std::max<drift::TimeUs>(0, clipSpan - 1));
    const drift::TimeUs from = clip.srcIn + offset;
    const drift::TimeUs span = std::min(kPreviewSpan, clip.srcOut - from);

    m_cancel.storeRelaxed(0);
    m_progress = 0.0;
    emit progressChanged();
    m_status = tr("Starting…");
    emit statusChanged();
    m_running = true;
    emit runningChanged();

    const QString path = clip.path;
    const QString cleanPath = drift::newDenoisePath(QStringLiteral("-preview"));
    const QString origPath = drift::newDenoisePath(QStringLiteral("-original"));
    if (cleanPath.isEmpty() || origPath.isEmpty()) {
        m_running = false;
        emit runningChanged();
        m_app->setLastMessage(tr("Could not create a preview file"), QStringLiteral("error"));
        return;
    }

    (void)QtConcurrent::run([this, path, from, span, cleanPath, origPath]() {
        QString error;
        const bool ok = renderAudio(path, from, span, cleanPath, origPath, 0.0, 1.0, &error);
        QMetaObject::invokeMethod(
            this,
            [this, ok, error, cleanPath, origPath]() {
                m_running = false;
                emit runningChanged();
                m_progress = ok ? 1.0 : 0.0;
                emit progressChanged();
                m_status = ok ? tr("Ready") : error;
                emit statusChanged();
                if (!ok) {
                    QFile::remove(cleanPath);
                    QFile::remove(origPath);
                    m_app->setLastMessage(error, QStringLiteral("error"));
                    emit finished(false, error);
                    return;
                }
                // Retire the pair this one replaces, only once the new pair is safely on disk.
                if (!m_previewClean.isEmpty())
                    QFile::remove(m_previewClean);
                if (!m_previewOriginal.isEmpty())
                    QFile::remove(m_previewOriginal);
                m_previewClean = cleanPath;
                m_previewOriginal = origPath;
                emit previewReady(origPath, cleanPath);
            },
            Qt::QueuedConnection);
    });
}

void DenoiseController::apply(int trackIndex, int clipIndex)
{
    if (m_running) {
        m_app->setLastMessage(tr("Noise removal already in progress"), QStringLiteral("warning"));
        return;
    }
    if (trackIndex < 0 || trackIndex >= m_app->m_project.tracks().size())
        return;
    const drift::Track &track = m_app->m_project.tracks().at(trackIndex);
    if (clipIndex < 0 || clipIndex >= track.clips.size())
        return;

    const drift::Clip clip = track.clips.at(clipIndex);
    if (clip.type != drift::ClipType::Audio && clip.type != drift::ClipType::Video) {
        m_app->setLastMessage(tr("Select a video or audio clip"), QStringLiteral("warning"));
        return;
    }
    if (clip.path.isEmpty() || clip.srcOut <= clip.srcIn) {
        m_app->setLastMessage(tr("Clip has no audio"), QStringLiteral("warning"));
        return;
    }

    m_app->setPlaying(false);

    m_cancel.storeRelaxed(0);
    m_progress = 0.0;
    emit progressChanged();
    m_status = tr("Starting…");
    emit statusChanged();
    m_running = true;
    emit runningChanged();
    m_app->setLastMessage(tr("Removing noise…"));

    const QString path = clip.path;
    const drift::TimeUs srcIn = clip.srcIn;
    const drift::TimeUs span = clip.srcOut - clip.srcIn;
    // Resolved by id at the end rather than by index: the timeline can be edited while the job
    // runs, and a stale index would attach the audio to the wrong clip.
    const QString clipId = clip.id;
    const QString outPath = drift::newDenoisePath();
    if (outPath.isEmpty()) {
        m_running = false;
        emit runningChanged();
        m_app->setLastMessage(tr("Could not create an output file"), QStringLiteral("error"));
        return;
    }

    (void)QtConcurrent::run([this, path, srcIn, span, outPath, clipId]() {
        QString error;
        const bool ok = renderAudio(path, srcIn, span, outPath, QString(), 0.0, 1.0, &error);
        QMetaObject::invokeMethod(
            this,
            [this, ok, error, outPath, clipId]() {
                m_running = false;
                emit runningChanged();
                m_progress = ok ? 1.0 : 0.0;
                emit progressChanged();
                m_status = ok ? tr("Done") : error;
                emit statusChanged();
                if (!ok) {
                    QFile::remove(outPath);
                    m_app->setLastMessage(error, QStringLiteral("error"));
                    emit finished(false, error);
                    return;
                }
                finalize(clipId, outPath);
            },
            Qt::QueuedConnection);
    });
}

void DenoiseController::finalize(const QString &clipId, const QString &audioPath)
{
    int trackIndex = -1;
    int clipIndex = -1;
    for (int t = 0; t < m_app->m_project.tracks().size() && trackIndex < 0; ++t) {
        const drift::Track &track = m_app->m_project.tracks().at(t);
        for (int c = 0; c < track.clips.size(); ++c) {
            if (track.clips.at(c).id == clipId) {
                trackIndex = t;
                clipIndex = c;
                break;
            }
        }
    }
    if (trackIndex < 0) {
        // The clip was deleted while the job ran; the audio has nothing to attach to.
        QFile::remove(audioPath);
        const QString message = QStringLiteral("The clip no longer exists");
        m_app->setLastMessage(message, QStringLiteral("error"));
        emit finished(false, message);
        return;
    }

    const drift::Project before = m_app->m_project;
    const drift::Clip source = m_app->m_project.tracks().at(trackIndex).clips.at(clipIndex);

    // Everything about the clip carries over except the media it points at. srcIn/srcOut rebase
    // because the render already baked in the source window, while speed and reverse stay — the
    // render is in the source's time base, so the new clip lines up with the original.
    drift::Clip clip = source;
    clip.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    clip.linkId.clear();
    clip.assetId.clear();
    clip.path = audioPath;
    clip.thumbnailPath.clear();
    clip.filmstripPath.clear();
    clip.type = drift::ClipType::Audio;
    clip.mask = drift::Mask{};
    clip.srcIn = 0;
    clip.srcOut = source.srcOut - source.srcIn;
    clip.name = (source.name.isEmpty() ? tr("Clip") : source.name)
                + tr(" (denoised)");

    const int newTrack =
        drift::insertTrackAboveForClipType(m_app->m_project, trackIndex, drift::ClipType::Audio);
    m_app->m_project.tracks()[newTrack].clips.append(clip);

    m_app->pushProjectEdit(before, tr("Remove noise"));
    m_app->finishEdit(tr("Noise removed"));
    m_app->selectClip(newTrack, m_app->m_project.tracks().at(newTrack).clips.size() - 1);
    m_app->setLastMessage(tr("Noise removed"), QStringLiteral("success"));
    emit finished(true, tr("Noise removed"));
}

