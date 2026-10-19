#pragma once

#include "core/base/Time.h"

#include <QObject>
#include <QSize>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include <optional>
#include <utility>

class AppController;

namespace drift {
struct MediaAsset;
}

// Video restore and enhance (decompression and upscaling models), reached from QML as EditorState.restore.
class RestoreController : public QObject
{
    Q_OBJECT

public:
    explicit RestoreController(AppController *app, QObject *parent = nullptr);

    // Restore models (compression removal, upscaling), installed addons and custom .onnx files:
    // [{id, name, task: "decompress"|"upscale", scale, custom}].
    Q_INVOKABLE QVariantList models();
    // The folder custom restore models are read from, created if missing.
    Q_INVOKABLE QString modelsFolder();
    // The enhance window works on a target: a clip id (its used source range) or a bin video's
    // asset id (the whole file).
    //
    // Runs the target through an optional decompression model, then an optional upscaler, into a
    // new bin item beside its media, as a JobRegistry "restore" job targeting that id. Either
    // model id may be empty, not both. Returns the job id, or empty when it could not start (the
    // reason goes to lastMessage).
    Q_INVOKABLE QString run(const QString &targetId, const QString &decompressModel,
                            const QString &upscaleModel);
    Q_INVOKABLE void cancel(const QString &targetId);
    // {active, progress, status, error, kind} of the newest restore or restore-preview job for a
    // target; empty if there is none.
    Q_INVOKABLE QVariantMap job(const QString &targetId) const;
    // The enhance window's before/after. Decodes the frame `offsetSeconds` into the target at
    // source resolution as image://segment/restore-original, dropping any result. Calls made
    // while a decode runs collapse into the newest, so it can follow a dragged slider.
    Q_INVOKABLE void setPreviewFrame(const QString &targetId, double offsetSeconds);
    // Runs the models over that frame as a JobRegistry "restore-preview" job; the result becomes
    // image://segment/restore-enhanced. Returns the job id, or empty when it could not start.
    Q_INVOKABLE QString preview(const QString &targetId, const QString &decompressModel,
                                const QString &upscaleModel);
    // {seconds, width, height (upright), fps} of a target.
    Q_INVOKABLE QVariantMap targetInfo(const QString &targetId) const;
    // {factor, calibrated}: how this machine's CPU compares with the one the models'
    // secondsPerMegapixel were measured on. Each preview run refines it.
    Q_INVOKABLE QVariantMap speed() const;
    // {revision, width, height, enhancedWidth, enhancedHeight, loading}
    Q_INVOKABLE QVariantMap previewState() const;
    Q_INVOKABLE void endPreview();

signals:
    void jobChanged(const QString &targetId);
    void previewChanged();

private:
    struct RestoreSource
    {
        QString path;
        drift::TimeUs srcIn = 0;
        drift::TimeUs srcOut = 0;
        int rotationCorrection = 0;
        const drift::MediaAsset *asset = nullptr;
    };
    // A clip id or asset id resolved to the video it reads; nullopt when it is neither.
    std::optional<RestoreSource> source(const QString &targetId) const;
    void calibrateSpeed(const QStringList &modelIds, double megapixels, double seconds);

    AppController *m_app = nullptr;
    // Enhance window preview. The generation drops a frame decode or model run that finishes
    // after the frame has moved on.
    int m_previewRevision = 0;
    quint64 m_previewGeneration = 0;
    bool m_frameLoading = false;
    QSize m_originalSize;
    QSize m_enhancedSize;
    bool m_decodeBusy = false;
    std::optional<std::pair<QString, double>> m_pendingFrame;
};
