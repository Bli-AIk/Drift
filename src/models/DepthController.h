#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class AppController;

// Depth estimation for a clip, reached from QML as EditorState.depth.
class DepthController : public QObject
{
    Q_OBJECT

public:
    explicit DepthController(AppController *app, QObject *parent = nullptr);

    // Estimates the clip's depth for the depth effects as a JobRegistry "depth" job targeting the
    // clip id. Returns the job id, or empty when it could not start (the reason goes to
    // lastMessage). The sidecar lands on the clip through the undo stack.
    Q_INVOKABLE QString estimate(int trackIndex, int clipIndex, bool highQuality = false);
    Q_INVOKABLE void cancel(const QString &clipId);
    Q_INVOKABLE void clear(int trackIndex, int clipIndex);
    Q_INVOKABLE bool available();
    // {active, progress, status, error} of the newest depth job for a clip; empty if there is none.
    Q_INVOKABLE QVariantMap job(const QString &clipId) const;
    // Normalised depth (0 far, 1 near) under a point of the clip's frame, given in 0..1 frame
    // coordinates, at a timeline time (negative: the playhead). -1 when the clip has no depth.
    Q_INVOKABLE double sampleAt(int trackIndex, int clipIndex, double nx, double ny,
                                double atSeconds = -1.0);

signals:
    void jobChanged(const QString &clipId);

private:
    void finalize(const QString &clipId, const QString &path);

    AppController *m_app = nullptr;
};
