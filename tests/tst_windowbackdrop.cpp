#include <QtTest>

#include <QColor>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QSignalSpy>
#include <QTemporaryDir>

#include "theme/ThemeManager.h"
#include "theme/WindowBackdrop.h"

class WindowBackdropTest : public QObject
{
    Q_OBJECT

private slots:
    void supportedBackdropsMatchPlatform();
    void backdropResolution();
    void windowBackgroundAlpha();
    void translucentWindowsPersistsAndRequestsRestart();
    void mainRequestsAlphaAndRegistersSingleton();
    void attachIgnoresNull();

private:
    bool writeTheme(const QString &path, const char *json);
};

bool WindowBackdropTest::writeTheme(const QString &path, const char *json)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    return file.write(json) == qstrlen(json);
}

void WindowBackdropTest::supportedBackdropsMatchPlatform()
{
    const QStringList list = WindowBackdrop::shared()->supportedBackdrops();
    QVERIFY(!list.isEmpty());
    QCOMPARE(list.first(), QStringLiteral("none"));
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    QCOMPARE(list, QStringList({QStringLiteral("none"), QStringLiteral("blur")}));
#elif defined(Q_OS_MACOS)
    QCOMPARE(list, QStringList({QStringLiteral("none"), QStringLiteral("vibrancy"), QStringLiteral("blur")}));
#elif defined(Q_OS_WIN)
    QVERIFY(list.contains(QStringLiteral("blur")));
    if (list.contains(QStringLiteral("mica"))) {
        QVERIFY(list.contains(QStringLiteral("acrylic")));
        QVERIFY(list.contains(QStringLiteral("blur")));
    }
#else
    QCOMPARE(list, QStringList({QStringLiteral("none")}));
#endif
}

void WindowBackdropTest::backdropResolution()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString mica = dir.filePath(QStringLiteral("mica.json"));
    const QString blur = dir.filePath(QStringLiteral("blur.json"));
    QVERIFY(writeTheme(mica, R"({
        "name": "wb-mica",
        "variant": "dark",
        "window": { "backdrop": "mica", "backgroundOpacity": 1.0, "translucent": true }
    })"));
    QVERIFY(writeTheme(blur, R"({
        "name": "wb-blur",
        "variant": "light",
        "window": { "backdrop": "blur", "backgroundOpacity": 0.4, "translucent": true }
    })"));

    WindowBackdrop *backdrop = WindowBackdrop::shared();
    ThemeManager *themes = ThemeManager::shared();
    WindowBackdrop::noteProcessTranslucency(false);
    QVERIFY(themes->loadTheme(QStringLiteral("dark")));
    QCOMPARE(backdrop->backdrop(), QStringLiteral("none"));

    // An unsupported material stays "none" even after this process is translucent.
    QVERIFY(themes->loadTheme(mica));
    WindowBackdrop::noteProcessTranslucency(true);
    QCOMPARE(backdrop->translucencyActive(), true);
    QCOMPARE(backdrop->backdrop(), QStringLiteral("none"));

    // A supported material is still "none" while the surface has no alpha channel.
    QVERIFY(themes->loadTheme(blur));
    WindowBackdrop::noteProcessTranslucency(false);
    QCOMPARE(backdrop->backdrop(), QStringLiteral("none"));

    QSignalSpy spy(backdrop, &WindowBackdrop::backdropChanged);
    WindowBackdrop::noteProcessTranslucency(true);
    QCOMPARE(backdrop->backdrop(), QStringLiteral("blur"));
    QCOMPARE(spy.count(), 1);

    WindowBackdrop::noteProcessTranslucency(false);
    QCOMPARE(backdrop->backdrop(), QStringLiteral("none"));
}

void WindowBackdropTest::windowBackgroundAlpha()
{
    WindowBackdrop *backdrop = WindowBackdrop::shared();
    const QColor opaque(13, 13, 13);
    const QColor half(13, 13, 13, 128);

    WindowBackdrop::noteProcessTranslucency(false);
    QCOMPARE(backdrop->windowBackground(opaque, 0.25), opaque);
    const QColor forced = backdrop->windowBackground(half, 0.25);
    QCOMPARE(forced.red(), 13);
    QCOMPARE(forced.green(), 13);
    QCOMPARE(forced.blue(), 13);
    QCOMPARE(forced.alpha(), 255);

    WindowBackdrop::noteProcessTranslucency(true);
    QCOMPARE(backdrop->windowBackground(opaque, 1.0), opaque);
    const QColor scaled = backdrop->windowBackground(opaque, 0.5);
    QVERIFY(qAbs(scaled.alphaF() - 0.5) < 0.01);
    QCOMPARE(scaled.red(), 13);
    const QColor both = backdrop->windowBackground(half, 0.5);
    QVERIFY(qAbs(both.alphaF() - 0.25) < 0.02);
    QCOMPARE(backdrop->windowBackground(opaque, 2.0), opaque);
    QCOMPARE(backdrop->windowBackground(opaque, -1.0).alpha(), 0);

    QCOMPARE(backdrop->windowBackground(QColor(), 1.0), QColor());
    WindowBackdrop::noteProcessTranslucency(false);
}

void WindowBackdropTest::translucentWindowsPersistsAndRequestsRestart()
{
    WindowBackdrop *backdrop = WindowBackdrop::shared();
    QCOMPARE(backdrop->translucentWindows(), false);
    QCOMPARE(backdrop->restartRequired(), false);

    QSignalSpy windows(backdrop, &WindowBackdrop::translucentWindowsChanged);
    QSignalSpy restart(backdrop, &WindowBackdrop::restartRequiredChanged);
    backdrop->setTranslucentWindows(false);
    QCOMPARE(windows.count(), 0);
    QCOMPARE(restart.count(), 0);

    backdrop->setTranslucentWindows(true);
    QCOMPARE(backdrop->translucentWindows(), true);
    QCOMPARE(backdrop->restartRequired(), true);
    QCOMPARE(windows.count(), 1);
    QCOMPARE(restart.count(), 1);

    QSettings saved;
    saved.beginGroup(QStringLiteral("Theme"));
    QCOMPARE(saved.value(QStringLiteral("translucentWindows")).toBool(), true);
    saved.endGroup();

    backdrop->setTranslucentWindows(false);
    QCOMPARE(backdrop->restartRequired(), false);
    QSettings again;
    again.beginGroup(QStringLiteral("Theme"));
    QCOMPARE(again.value(QStringLiteral("translucentWindows")).toBool(), false);
}

void WindowBackdropTest::mainRequestsAlphaAndRegistersSingleton()
{
    QFile mainFile(QStringLiteral(DRIFT_MAIN_CPP));
    QVERIFY2(mainFile.open(QIODevice::ReadOnly | QIODevice::Text), qPrintable(mainFile.errorString()));
    const QString source = QString::fromUtf8(mainFile.readAll());
    QVERIFY(source.contains(QStringLiteral("WindowBackdrop::registerSingleton()")));
    QVERIFY(source.contains(QStringLiteral("WindowBackdrop::startupWantsAlphaBuffer()")));
    QVERIFY(source.contains(QStringLiteral("WindowBackdrop::noteProcessTranslucency")));
    QVERIFY(source.contains(QStringLiteral("setAlphaBufferSize(8)")));
    QVERIFY(source.contains(QStringLiteral("QQuickWindow::setDefaultAlphaBuffer(true)")));
}

void WindowBackdropTest::attachIgnoresNull()
{
    WindowBackdrop::shared()->attach(nullptr);
}

int main(int argc, char *argv[])
{
    QTemporaryDir configDir;
    if (!configDir.isValid())
        return 2;
    // Keep the test off the user's CutWire Drift.conf. NativeFormat is IniFormat
    // on Unix; set both so either spelling opens this directory.
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, configDir.path());
    QSettings::setPath(QSettings::NativeFormat, QSettings::UserScope, configDir.path());
    QCoreApplication::setOrganizationName(QStringLiteral("CutWireDriftWindowBackdropTest"));
    QCoreApplication::setApplicationName(QStringLiteral("CutWireDriftWindowBackdropTest"));

    QCoreApplication app(argc, argv);
    WindowBackdropTest test;
    return QTest::qExec(&test, argc, argv);
}

#include "tst_windowbackdrop.moc"
