#pragma once

#include <QImage>
#include <QMetaObject>
#include <QObject>

class AppController;

// The Scopes panel's source: while a scope is open, the preview's frames arrive here and the
// histogram, waveform and vectorscope are drawn for each one as image://color/scope/<kind>.
class ScopesController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int serial READ serial NOTIFY serialChanged)
    Q_PROPERTY(bool parade READ parade WRITE setParade NOTIFY paradeChanged)
    Q_PROPERTY(bool active READ active NOTIFY activeChanged)

public:
    explicit ScopesController(AppController *app, QObject *parent = nullptr);

    int serial() const { return m_serial; }
    bool parade() const { return m_parade; }
    void setParade(bool on);
    bool active() const { return m_count > 0; }

    Q_INVOKABLE void acquire();
    Q_INVOKABLE void release();

signals:
    void serialChanged();
    void paradeChanged();
    void activeChanged();

private:
    void onScopeFrame(const QImage &frame);
    void startJob(const QImage &frame);
    void onJobFinished();

    AppController *m_app = nullptr;
    int m_count = 0;
    int m_serial = 0;
    bool m_parade = false;
    bool m_jobRunning = false;
    QImage m_pending;
    QMetaObject::Connection m_frameConnection;
};
