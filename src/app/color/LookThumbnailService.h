#pragma once

#include <QObject>
#include <QString>

#include <functional>
#include <memory>

class QTimer;

namespace drift {
class Project;
}

// Publishes look/none: the current timeline frame with the grade applied but no look.
// ColorImageProvider derives each look's thumbnail from it on demand. Requests are debounced, and
// a request that arrives mid-render is run once the render finishes.
class LookThumbnailService : public QObject
{
    Q_OBJECT

public:
    // Called on the GUI thread at render time for the timeline to thumbnail.
    explicit LookThumbnailService(std::function<drift::Project()> projectSnapshot,
                                  QObject *parent = nullptr);
    ~LookThumbnailService() override;

    void request(qint64 timeUs, const QString &gradeHostClipId, int gradeEffectIndex);
    void setActive(bool active);

signals:
    void thumbnailsReady(int serial);

private:
    void fire();
    void startRender();
    void onRenderFinished(int serial);

    std::function<drift::Project()> m_projectSnapshot;
    QTimer *m_debounce = nullptr;
    qint64 m_timeUs = 0;
    QString m_gradeHostClipId;
    int m_gradeEffectIndex = -1;
    bool m_active = false;
    bool m_rendering = false;
    bool m_queued = false;
    int m_serial = 0;
};
