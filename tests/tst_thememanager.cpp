#include <QtTest>

#include <QColor>
#include <QDir>
#include <QByteArray>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QSignalSpy>
#include <QStandardPaths>
#include <QVariantList>

#include "theme/ThemeManager.h"

class ThemeManagerTest : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void init();

    void builtinsLoadDarkAndLight();
    void resolvesReferences();
    void extendsMergesOverBase();
    void referenceCycleDoesNotHang();
    void extendsCycleDoesNotHang();
    void invalidThemeFallsBack();
    void singletonRegistrationExposesThemeManager();
    void mainRegistersThemeManager();
    void liveBindingUpdates();

private:
    QString themesDir() const;
    bool writeJson(const QString &relativePath, const char *json) const;
    static QColor tokenColor(const ThemeManager &manager, const char *path);
};

void ThemeManagerTest::initTestCase()
{
    QStandardPaths::setTestModeEnabled(true);
    QCoreApplication::setOrganizationName(QStringLiteral("DriftThemeTest"));
    QCoreApplication::setApplicationName(QStringLiteral("DriftThemeTest"));
}

void ThemeManagerTest::init()
{
    QDir dir(themesDir());
    if (dir.exists())
        QVERIFY(dir.removeRecursively());
}

QString ThemeManagerTest::themesDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + QStringLiteral("/themes");
}

bool ThemeManagerTest::writeJson(const QString &relativePath, const char *json) const
{
    const QString path = themesDir() + QLatin1Char('/') + relativePath;
    if (!QDir().mkpath(QFileInfo(path).path()))
        return false;
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    const QByteArray bytes(json);
    return file.write(bytes) == bytes.size();
}

QColor ThemeManagerTest::tokenColor(const ThemeManager &manager, const char *path)
{
    return manager.token(QString::fromLatin1(path)).value<QColor>();
}

void ThemeManagerTest::builtinsLoadDarkAndLight()
{
    ThemeManager manager;
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));
    QVERIFY(manager.availableThemes().contains(QStringLiteral("dark")));
    QVERIFY(manager.availableThemes().contains(QStringLiteral("light")));
    QCOMPARE(tokenColor(manager, "semantic.surface.app"), QColor(QStringLiteral("#0d0d0d")));
    QCOMPARE(tokenColor(manager, "semantic.primary"), QColor(QStringLiteral("#F8B81C")));
    QCOMPARE(tokenColor(manager, "semantic.scrim"), QColor(QStringLiteral("#00000066")));
    QCOMPARE(tokenColor(manager, "semantic.clip.audio"), QColor(QStringLiteral("#8F5DBA")));
    QCOMPARE(tokenColor(manager, "semantic.gizmo.x"), QColor(QStringLiteral("#f0475a")));
    QCOMPARE(tokenColor(manager, "semantic.clip.waveform"), QColor(QStringLiteral("#ffffffb3")));
    QCOMPARE(tokenColor(manager, "semantic.panel.sliderTrack"), QColor(QStringLiteral("#505050")));
    QCOMPARE(manager.token(QStringLiteral("metrics.radius.sm")).toDouble(), 5.6);
    QCOMPARE(manager.token(QStringLiteral("metrics.controlHeight.pointer")).toDouble(), 30.0);
    QCOMPARE(manager.token(QStringLiteral("metrics.controlHeight.touch")).toDouble(), 44.0);
    QCOMPARE(manager.token(QStringLiteral("motion.easing")).toString(), QStringLiteral("OutQuint"));
    QCOMPARE(manager.token(QStringLiteral("motion.easingInOut")).toString(), QStringLiteral("InOutQuart"));
    QCOMPARE(manager.token(QStringLiteral("typography.fontSize.base")).toDouble(), 14.72);
    QCOMPARE(manager.token(QStringLiteral("typography.fontWeight.semibold")).toInt(), 600);
    QCOMPARE(manager.token(QStringLiteral("window.translucent")).toBool(), false);
    QCOMPARE(manager.token(QStringLiteral("window.backdrop")).toString(), QStringLiteral("none"));
    QCOMPARE(manager.token(QStringLiteral("window.backgroundOpacity")).toDouble(), 1.0);
    QVERIFY(manager.components()->isEmpty());
    QVERIFY(manager.overrideUrl(QStringLiteral("button")).isEmpty());

    const QVariantList ramp = manager.token(QStringLiteral("semantic.keyframe.ramp")).toList();
    QCOMPARE(ramp.size(), 8);
    QCOMPARE(ramp.at(0).value<QColor>(), QColor(QStringLiteral("#38bdf8")));
    QCOMPARE(ramp.at(1).value<QColor>(), QColor(QStringLiteral("#fb923c")));

    QSignalSpy spy(&manager, &ThemeManager::themeChanged);
    manager.setVariant(QStringLiteral("light"));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(manager.currentTheme(), QStringLiteral("light"));
    QCOMPARE(tokenColor(manager, "semantic.surface.app"), QColor(QStringLiteral("#ffffff")));
    QCOMPARE(tokenColor(manager, "semantic.panel.sliderTrack"), tokenColor(manager, "semantic.panel.muted"));
    QCOMPARE(tokenColor(manager, "semantic.panel.muted"), QColor(QStringLiteral("#d4d4d4")));
    QCOMPARE(tokenColor(manager, "semantic.accentOnPanel"), QColor(QStringLiteral("#8a6300")));
    QCOMPARE(tokenColor(manager, "semantic.panel.scrollbar.handlePressed"), tokenColor(manager, "semantic.foreground"));
    QCOMPARE(tokenColor(manager, "semantic.skeleton"), QColor(QStringLiteral("#e8e8e8")));
    QCOMPARE(tokenColor(manager, "semantic.clip.beat.bar"), QColor(QStringLiteral("#1f6fb24d")));
    QCOMPARE(tokenColor(manager, "semantic.preview.textStyleBorder"), QColor(QStringLiteral("#2a2a2a")));
    // Built-in documents stay readable after the live theme swaps.
    QCOMPARE(manager.builtinToken(QStringLiteral("dark"), QStringLiteral("semantic.surface.app")).value<QColor>(),
             QColor(QStringLiteral("#0d0d0d")));

    manager.setVariant(QStringLiteral("light"));
    QCOMPARE(spy.count(), 1);
    manager.setVariant(QStringLiteral("nope"));
    QCOMPARE(manager.currentTheme(), QStringLiteral("light"));
}

void ThemeManagerTest::resolvesReferences()
{
    ThemeManager manager;
    QCOMPARE(tokenColor(manager, "semantic.focusRing"), tokenColor(manager, "semantic.primary"));
    QCOMPARE(tokenColor(manager, "semantic.clip.adjustment.video"), tokenColor(manager, "semantic.clip.effect"));
    QCOMPARE(tokenColor(manager, "semantic.clip.effect"), QColor(QStringLiteral("#5d93ba")));
    QCOMPARE(tokenColor(manager, "semantic.keyframe.curves.x"), QColor(QStringLiteral("#16a9f3")));
    QCOMPARE(tokenColor(manager, "semantic.keyframe.curves.volume"), QColor(QStringLiteral("#2dd4bf")));
    QCOMPARE(tokenColor(manager, "semantic.accentOnPanel"), tokenColor(manager, "semantic.primary"));

    manager.setVariant(QStringLiteral("light"));
    QCOMPARE(tokenColor(manager, "semantic.focusRing"), tokenColor(manager, "semantic.primary"));
    QCOMPARE(tokenColor(manager, "semantic.panel.scrollbar.track"), tokenColor(manager, "semantic.panel.border"));
    QCOMPARE(tokenColor(manager, "semantic.panel.scrollbar.handle"), tokenColor(manager, "semantic.panel.muted"));
    QCOMPARE(tokenColor(manager, "semantic.panel.scrollbar.handleHover"), tokenColor(manager, "semantic.mutedForeground"));
}

void ThemeManagerTest::extendsMergesOverBase()
{
    QVERIFY(writeJson("base.json", R"({
        "name": "base",
        "variant": "dark",
        "palette": { "red": "#ff0000", "blue": "#0000ff" },
        "semantic": { "danger": "$palette.red", "info": "$palette.blue" },
        "metrics": { "size": 10, "nested": { "a": 1, "b": 2 } },
        "components": {}
    })"));
    QVERIFY(writeJson("child.json", R"({
        "name": "child",
        "extends": "base",
        "palette": { "red": "#00ff00" },
        "metrics": { "nested": { "b": 9 } },
        "components": { "button": { "primary": { "background": "$semantic.danger" } } }
    })"));
    QVERIFY(writeJson("packaged/theme.json", R"({
        "name": "packaged",
        "extends": "base",
        "palette": { "blue": "#0000aa" }
    })"));

    ThemeManager manager;
    const QStringList themes = manager.availableThemes();
    QVERIFY(themes.contains(QStringLiteral("base")));
    QVERIFY(themes.contains(QStringLiteral("child")));
    QVERIFY(themes.contains(QStringLiteral("packaged")));

    QVERIFY(manager.loadTheme(QStringLiteral("child")));
    QCOMPARE(manager.currentTheme(), QStringLiteral("child"));
    QCOMPARE(tokenColor(manager, "semantic.danger"), QColor(QStringLiteral("#00ff00")));
    QCOMPARE(tokenColor(manager, "semantic.info"), QColor(QStringLiteral("#0000ff")));
    QCOMPARE(manager.token(QStringLiteral("metrics.size")).toDouble(), 10.0);
    QCOMPARE(manager.token(QStringLiteral("metrics.nested.a")).toDouble(), 1.0);
    QCOMPARE(manager.token(QStringLiteral("metrics.nested.b")).toDouble(), 9.0);
    QCOMPARE(tokenColor(manager, "components.button.primary.background"), QColor(QStringLiteral("#00ff00")));

    QVERIFY(manager.loadTheme(themesDir() + QStringLiteral("/packaged")));
    QCOMPARE(manager.currentTheme(), QStringLiteral("packaged"));
    QCOMPARE(tokenColor(manager, "semantic.info"), QColor(QStringLiteral("#0000aa")));
    QCOMPARE(tokenColor(manager, "semantic.danger"), QColor(QStringLiteral("#ff0000")));

    // A user theme stays put when the app toggles dark/light.
    manager.setVariant(QStringLiteral("light"));
    QCOMPARE(manager.currentTheme(), QStringLiteral("packaged"));
    QCOMPARE(tokenColor(manager, "semantic.info"), QColor(QStringLiteral("#0000aa")));
}

void ThemeManagerTest::referenceCycleDoesNotHang()
{
    QVERIFY(writeJson("refcycle.json", R"({
        "name": "refcycle",
        "variant": "dark",
        "palette": { "a": "$palette.b", "b": "$palette.a", "ok": "#112233" },
        "semantic": { "fine": "$palette.ok", "bad": "$palette.a" }
    })"));

    ThemeManager manager;
    QElapsedTimer timer;
    timer.start();
    QVERIFY(manager.loadTheme(QStringLiteral("refcycle")));
    QVERIFY(timer.elapsed() < 1000);
    QCOMPARE(manager.currentTheme(), QStringLiteral("refcycle"));
    QCOMPARE(tokenColor(manager, "semantic.fine"), QColor(QStringLiteral("#112233")));
    QVERIFY(manager.token(QStringLiteral("semantic.bad")).typeId() == QMetaType::QString);
}

void ThemeManagerTest::extendsCycleDoesNotHang()
{
    QVERIFY(writeJson("cycleA.json", R"({
        "name": "cycleA",
        "extends": "cycleB",
        "palette": { "red": "#ff0000" }
    })"));
    QVERIFY(writeJson("cycleB.json", R"({
        "name": "cycleB",
        "extends": "cycleA",
        "palette": { "red": "#00ff00" }
    })"));

    ThemeManager manager;
    QCOMPARE(tokenColor(manager, "semantic.primary"), QColor(QStringLiteral("#F8B81C")));
    QElapsedTimer timer;
    timer.start();
    QVERIFY(!manager.loadTheme(QStringLiteral("cycleA")));
    QVERIFY(timer.elapsed() < 1000);
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));
    QCOMPARE(tokenColor(manager, "semantic.primary"), QColor(QStringLiteral("#F8B81C")));
}

void ThemeManagerTest::invalidThemeFallsBack()
{
    ThemeManager manager;
    QSignalSpy spy(&manager, &ThemeManager::themeChanged);
    QVERIFY(!manager.loadTheme(QStringLiteral("/no/such/drift-theme.json")));
    QVERIFY(!manager.loadTheme(QStringLiteral("")));
    QCOMPARE(spy.count(), 0);
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));

    QVERIFY(writeJson("broken.json", "{"));
    QVERIFY(!manager.loadTheme(QStringLiteral("broken")));
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));
    QCOMPARE(tokenColor(manager, "semantic.surface.app"), QColor(QStringLiteral("#0d0d0d")));

    QVERIFY(writeJson("wrong-type.json", R"({
        "name": "wrong-type",
        "palette": ["not", "an", "object"]
    })"));
    QVERIFY(!manager.loadTheme(QStringLiteral("wrong-type")));
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));
    QCOMPARE(tokenColor(manager, "semantic.primary"), QColor(QStringLiteral("#F8B81C")));

    QVERIFY(writeJson("bad-color.json", R"({
        "name": "bad-color",
        "variant": "dark",
        "palette": { "x": "#gg0000", "ok": "#abcdef" },
        "semantic": { "fine": "$palette.ok" }
    })"));
    QVERIFY(manager.loadTheme(QStringLiteral("bad-color")));
    QCOMPARE(tokenColor(manager, "semantic.fine"), QColor(QStringLiteral("#abcdef")));
    manager.setVariant(QStringLiteral("dark"));
    // The bad theme is a user theme, so the variant request must not clobber it.
    QCOMPARE(manager.currentTheme(), QStringLiteral("bad-color"));
    QVERIFY(manager.loadTheme(QStringLiteral("dark")));
    QCOMPARE(manager.currentTheme(), QStringLiteral("dark"));
}

void ThemeManagerTest::singletonRegistrationExposesThemeManager()
{
    // Same call main() makes. This test does not register the type itself.
    ThemeManager::registerSingleton();
    QVERIFY(ThemeManager::shared()->loadTheme(QStringLiteral("dark")));

    QQmlEngine engine;
    QQmlComponent component(&engine);
    component.setData(R"(import QtQuick
import Drift
QtObject {
    property color app: ThemeManager.semantic.surface.app
})", QUrl());
    QVERIFY2(!component.isError(), qPrintable(component.errorString()));
    QObject *object = component.create();
    QVERIFY(object);
    QCOMPARE(object->property("app").value<QColor>(), QColor(QStringLiteral("#0d0d0d")));
    delete object;
}

void ThemeManagerTest::mainRegistersThemeManager()
{
    // Drift is an executable-backed module, so a test process cannot import the
    // app's plugin. The guard is that main() goes through registerSingleton(),
    // which singletonRegistrationExposesThemeManager() actually loads QML through.
    QFile mainFile(QStringLiteral(DRIFT_MAIN_CPP));
    QVERIFY2(mainFile.open(QIODevice::ReadOnly | QIODevice::Text), qPrintable(mainFile.errorString()));
    const QString source = QString::fromUtf8(mainFile.readAll());
    QVERIFY(source.contains(QStringLiteral("ThemeManager::registerSingleton()")));
}

void ThemeManagerTest::liveBindingUpdates()
{
    ThemeManager::registerSingleton();
    ThemeManager *manager = ThemeManager::shared();
    QVERIFY(manager->loadTheme(QStringLiteral("dark")));

    QQmlEngine engine;
    QQmlComponent component(&engine);
    component.setData(R"(import QtQuick
import Drift
QtObject {
    property color app: ThemeManager.semantic.surface.app
    property color border: ThemeManager.semantic.panel.border
    property real radius: ThemeManager.metrics.radius.sm
})", QUrl());
    QVERIFY2(!component.isError(), qPrintable(component.errorString()));
    QObject *object = component.create();
    QVERIFY(object);
    QCOMPARE(object->property("app").value<QColor>(), QColor(QStringLiteral("#0d0d0d")));
    QCOMPARE(object->property("border").value<QColor>(), QColor(QStringLiteral("#2e2e2e")));

    manager->setVariant(QStringLiteral("light"));
    QCOMPARE(object->property("app").value<QColor>(), QColor(QStringLiteral("#ffffff")));
    QCOMPARE(object->property("border").value<QColor>(), QColor(QStringLiteral("#dedede")));
    QCOMPARE(object->property("radius").toDouble(), 5.6);

    QVERIFY(writeJson("button-red.json", R"({
        "name": "button-red",
        "extends": "dark",
        "components": { "button": { "primary": { "background": "#ff0000" } } }
    })"));
    QVERIFY(manager->loadTheme(QStringLiteral("button-red")));

    QQmlComponent buttonComponent(&engine);
    buttonComponent.setData(R"(import QtQuick
import Drift
QtObject {
    property color background: ThemeManager.components.button.primary.background
})", QUrl());
    QVERIFY2(!buttonComponent.isError(), qPrintable(buttonComponent.errorString()));
    QObject *button = buttonComponent.create();
    QVERIFY(button);
    QCOMPARE(button->property("background").value<QColor>(), QColor(QStringLiteral("#ff0000")));

    QVERIFY(writeJson("button-green.json", R"({
        "name": "button-green",
        "extends": "dark",
        "components": { "button": { "primary": { "background": "#00ff00" } } }
    })"));
    QVERIFY(manager->loadTheme(QStringLiteral("button-green")));
    QCOMPARE(button->property("background").value<QColor>(), QColor(QStringLiteral("#00ff00")));
    // The shell binding is still attached to the same nested map.
    QCOMPARE(object->property("app").value<QColor>(), QColor(QStringLiteral("#0d0d0d")));

    delete button;
    delete object;
}

QTEST_MAIN(ThemeManagerTest)
#include "tst_thememanager.moc"
