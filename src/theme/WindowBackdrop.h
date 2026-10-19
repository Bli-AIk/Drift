#pragma once

#include <QColor>
#include <QObject>
#include <QQuickWindow>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

// Process-wide window translucency and native backdrop (Mica, Acrylic, vibrancy,
// compositor blur). The singleton QML binds to is the one main() publishes with
// registerSingleton(); QML_SINGLETON auto-registration does not run in this app.
//
// The alpha channel is a process decision: QSurfaceFormat and
// QQuickWindow::setDefaultAlphaBuffer() only affect windows created afterwards.
// translucentWindows is the persisted preference; translucencyActive reports
// whether this process actually created its windows with an alpha buffer.
class WindowBackdrop : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool translucentWindows READ translucentWindows WRITE setTranslucentWindows NOTIFY translucentWindowsChanged)
    Q_PROPERTY(bool translucencyActive READ translucencyActive CONSTANT)
    Q_PROPERTY(bool restartRequired READ restartRequired NOTIFY restartRequiredChanged)
    Q_PROPERTY(QString backdrop READ backdrop NOTIFY backdropChanged)
    Q_PROPERTY(QStringList supportedBackdrops READ supportedBackdrops CONSTANT)

public:
    static WindowBackdrop *shared();
    static void registerSingleton();

    // Desktop only, and only when QSettings Theme/translucentWindows is true.
    // Safe before QApplication; does not create the singleton. main() uses the
    // result to set the default surface format before any window exists.
    static bool startupWantsAlphaBuffer();
    // Records whether this process created windows with an alpha channel.
    // main() calls it once, before the singleton exists. Tests may call it
    // again to exercise backdrop resolution; QML treats the property as constant.
    static void noteProcessTranslucency(bool active);

    bool translucentWindows() const { return m_translucentWindows; }
    void setTranslucentWindows(bool enabled);

    bool translucencyActive() const;
    bool restartRequired() const { return m_restartRequired; }
    QString backdrop() const { return m_backdrop; }
    QStringList supportedBackdrops() const { return m_supported; }

    // Straight-alpha window color. When this process has no alpha buffer the
    // token's alpha is forced to 1 so a translucent theme does not clear the
    // window to black. When it does, ThemeManager.window.backgroundOpacity
    // (passed in so the QML binding subscribes to it) scales that alpha.
    // An already-matching color is returned unchanged.
    Q_INVOKABLE QColor windowBackground(const QColor &token, qreal backgroundOpacity) const;

    // Applies the current backdrop and keeps it updated across theme changes
    // and later shows. Safe to call more than once; a null window is ignored.
    Q_INVOKABLE void attach(QQuickWindow *window);

signals:
    void translucentWindowsChanged();
    void restartRequiredChanged();
    void backdropChanged();

private:
    explicit WindowBackdrop(QObject *parent = nullptr);
    ~WindowBackdrop() override;

    void refreshBackdrop();
    void reapplyAll();
    void applyTo(QQuickWindow *window);
    QString resolveBackdrop() const;
    bool themeVariantIsDark() const;

    bool m_translucentWindows = false;
    bool m_startupTranslucent = false;
    bool m_restartRequired = false;
    QString m_backdrop = QStringLiteral("none");
    QStringList m_supported;
    class WindowList;
    WindowList *m_windows = nullptr;
};
