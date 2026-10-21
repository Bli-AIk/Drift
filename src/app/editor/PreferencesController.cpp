#include "app/editor/PreferencesController.h"
#include "engine/encode/proxies/ProxyNaming.h"

#include "engine/gpu/device/GpuPreference.h"
#include "engine/decode/hw/HwAccel.h"
#include "engine/decode/hw/VaapiZeroCopy.h"
#include "engine/platform/AndroidUri.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QLibraryInfo>
#include <QLocale>
#if !defined(Q_OS_WASM)
#include <QProcess>
#endif
#include <QScreen>
#include <QSet>
#include <QSettings>
#include <QTranslator>
#include <QUrl>
#include <QVariantMap>

#ifdef Q_OS_ANDROID
#include <QJniEnvironment>
#include <QJniObject>
#endif

#include <cmath>
#include <limits>

namespace {

QTranslator g_appTranslator;
QTranslator g_qtTranslator;
QString g_appliedShell;
// QT_SCALE_FACTOR came from ui/scale rather than the user's environment.
bool g_uiScaleFromSettings = false;

QString storedUiLanguage()
{
    return QSettings().value(QStringLiteral("ui/language")).toString().trimmed();
}

bool storedUiLanguageChosen()
{
    return QSettings().value(QStringLiteral("ui/languageChosen"), false).toBool();
}

// True when this install has already been used as an editor, so a newly added first-launch
// language prompt must not appear for people who upgraded. Window geometry is written on the
// first show, so it is not a signal — last session / recents / an explicit language are.
bool looksLikeReturningInstall()
{
    QSettings settings;
    if (settings.contains(QStringLiteral("ui/language")))
        return true;
    if (!settings.value(QStringLiteral("lastSessionPath")).toString().isEmpty())
        return true;
    if (!settings.value(QStringLiteral("recentProjects")).toStringList().isEmpty())
        return true;
    return false;
}

bool needsFirstLaunchLanguagePrompt()
{
    if (storedUiLanguageChosen())
        return false;
    return !looksLikeReturningInstall();
}

void markUiLanguageChosen()
{
    QSettings().setValue(QStringLiteral("ui/languageChosen"), true);
}

// Settings that describe this machine or hold a credential or trust grant. Matched on the last
// path segment, so cloud/<provider>/apiKey and market/accessToken are caught without a list per
// provider. ui/layout/<panel> is matched by prefix: panel geometry is tied to the display.
bool isMachineOrSecretSetting(const QString &key)
{
    static const QSet<QString> kLeaves = {
        QStringLiteral("accessToken"), QStringLiteral("refreshToken"), QStringLiteral("expiresAt"),
        QStringLiteral("accountId"), QStringLiteral("accountName"), QStringLiteral("coins"),
        QStringLiteral("apiKey"), QStringLiteral("token"), QStringLiteral("consent"),
        QStringLiteral("consented"), QStringLiteral("trusted"),
        QStringLiteral("geometry"), QStringLiteral("maximized"), QStringLiteral("lastSessionPath"),
        QStringLiteral("recentProjects"), QStringLiteral("lastFolder"), QStringLiteral("lastDownloadDir"),
        QStringLiteral("lastCheck"), QStringLiteral("announcedVersion"), QStringLiteral("skippedVersion"),
        QStringLiteral("pendingVersion"), QStringLiteral("pendingUrl"), QStringLiteral("pendingAssetUrl"),
        QStringLiteral("pendingAssetName"), QStringLiteral("pendingAssetSha256"),
        QStringLiteral("pendingAssetSize"), QStringLiteral("pendingNotes"),
        QStringLiteral("variant"), QStringLiteral("outputDeviceId"), QStringLiteral("decodeMode"),
        QStringLiteral("hardwareDecode"), QStringLiteral("vaapiZeroCopy"), QStringLiteral("d3d11ZeroCopy"),
        QStringLiteral("mediaCodecZeroCopy"), QStringLiteral("preferredGpu"),
        QStringLiteral("speedFactor"), QStringLiteral("speedCalibrated"),
    };
    return key.startsWith(QLatin1String("ui/layout/"))
           || kLeaves.contains(key.section(QLatin1Char('/'), -1));
}

double normalizeUiScale(double scale)
{
    static const double kSteps[] = {1.0, 1.25, 1.5, 1.75, 2.0};
    double best = 1.0;
    double bestDist = std::numeric_limits<double>::max();
    for (double step : kSteps) {
        const double dist = std::abs(scale - step);
        if (dist < bestDist) {
            best = step;
            bestDist = dist;
        }
    }
    return best;
}

double appliedUiScaleFromEnvironment()
{
    bool ok = false;
    const double env = qEnvironmentVariable("QT_SCALE_FACTOR").toDouble(&ok);
    if (ok && env > 0.0)
        return env;
    return 1.0;
}

QLocale uiLocaleFromStored()
{
    const QString code = storedUiLanguage();
    return code.isEmpty() ? QLocale::system() : QLocale(code);
}

QString languageLabel(const QString &code)
{
    const QLocale loc(code);
    QString native = loc.nativeLanguageName();
    if (native.isEmpty())
        return code;
    if (code.contains(QLatin1Char('_')) || code.contains(QLatin1Char('-'))) {
        const QString territory = loc.nativeTerritoryName();
        if (!territory.isEmpty())
            native += QStringLiteral(" (%1)").arg(territory);
    }
    return native;
}

} // namespace

PreferencesController::PreferencesController(QObject *parent)
    : QObject(parent)
{
    QSettings settings;
    m_reopenLastProject = settings.value(QStringLiteral("editor/reopenLastProject"), false).toBool();
    m_timelineOverviewVisible =
        settings.value(QStringLiteral("ui/timelineOverviewVisible"), false).toBool();
    m_audioMixerVisible =
        settings.value(QStringLiteral("ui/audioMixerVisible"), false).toBool();
    m_audioMixerWidth = settings.value(QStringLiteral("ui/audioMixerWidth"), 0.0).toDouble();
    if (m_audioMixerWidth > 0)
        m_audioMixerWidth = qBound(160.0, m_audioMixerWidth, 2000.0);
    m_trackLabelsWidth = qBound(110.0,
        settings.value(QStringLiteral("ui/trackLabelsWidth"), 130.0).toDouble(), 320.0);
    m_timelineToolbarItems = settings.value(QStringLiteral("ui/timelineToolbarItems")).toStringList();
    m_timelineMenuItems = settings.value(QStringLiteral("ui/timelineMenuItems")).toStringList();
    m_proxyNamePatterns = settings.contains(QStringLiteral("proxy/namePatterns"))
        ? settings.value(QStringLiteral("proxy/namePatterns")).toStringList()
        : drift::defaultProxyNamePatterns();
    // Checked means "allowed", not "forced": with the key unset the engine is in Auto and
    // will use zero-copy on drivers it has been verified against, so showing the box
    // unchecked would contradict what the preview is actually doing. Unchecking writes an
    // explicit false, which turns it off everywhere.
#if defined(Q_OS_WIN)
    // Same switch, Windows' import: on by default, so checked unless explicitly turned off.
    m_vaapiZeroCopy = drift::d3d11ZeroCopyEnabled();
#else
    m_vaapiZeroCopy = drift::vaapiZeroCopyMode() != drift::VaapiZeroCopyMode::Off;
#endif
    m_preferredGpu = drift::gpu::preferenceId(drift::gpu::storedPreference());
    m_mediaCodecZeroCopy =
        settings.value(QStringLiteral("preview/mediaCodecZeroCopy"), false).toBool();
    m_invertTimelineScroll = settings.value(QStringLiteral("timeline/invertScroll"), false).toBool();
    m_uiLanguage = storedUiLanguage();
    m_needsUiLanguagePrompt = needsFirstLaunchLanguagePrompt();
    m_uiScale = storedUiScale();
    m_interfaceShell = storedInterfaceShell();
    // Unset means the user has never toggled the theme, so the UI keeps tracking the OS.
    const QVariant storedDarkMode = settings.value(QStringLiteral("ui/darkMode"));
    m_darkModeOverridden = storedDarkMode.isValid();
    m_darkModePreferred = storedDarkMode.toBool();
    // Likewise unset means the workspace still follows the canvas orientation.
    const QVariant storedWorkspace = settings.value(QStringLiteral("ui/workspaceLayout"));
    m_workspaceLayoutOverridden = storedWorkspace.isValid();
    if (m_workspaceLayoutOverridden) {
        m_workspaceLayoutPreferred = storedWorkspace.toString() == QStringLiteral("portrait")
            ? QStringLiteral("portrait")
            : QStringLiteral("landscape");
    }
}

void PreferencesController::setDarkModePreference(bool enabled)
{
    if (m_darkModeOverridden && m_darkModePreferred == enabled)
        return;
    m_darkModeOverridden = true;
    m_darkModePreferred = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/darkMode"), m_darkModePreferred);
    emit darkModePreferenceChanged();
}

void PreferencesController::clearDarkModePreference()
{
    if (!m_darkModeOverridden)
        return;
    m_darkModeOverridden = false;
    QSettings settings;
    settings.remove(QStringLiteral("ui/darkMode"));
    emit darkModePreferenceChanged();
}

void PreferencesController::setWorkspaceLayoutPreference(const QString &layout)
{
    const QString normalized = layout == QStringLiteral("portrait")
        ? QStringLiteral("portrait")
        : QStringLiteral("landscape");
    if (m_workspaceLayoutOverridden && m_workspaceLayoutPreferred == normalized)
        return;
    m_workspaceLayoutOverridden = true;
    m_workspaceLayoutPreferred = normalized;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/workspaceLayout"), m_workspaceLayoutPreferred);
    emit workspaceLayoutPreferenceChanged();
}

void PreferencesController::clearWorkspaceLayoutPreference()
{
    if (!m_workspaceLayoutOverridden)
        return;
    m_workspaceLayoutOverridden = false;
    QSettings settings;
    settings.remove(QStringLiteral("ui/workspaceLayout"));
    emit workspaceLayoutPreferenceChanged();
}

void PreferencesController::setTimelineOverviewVisible(bool visible)
{
    if (m_timelineOverviewVisible == visible)
        return;
    m_timelineOverviewVisible = visible;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/timelineOverviewVisible"), m_timelineOverviewVisible);
    emit timelineOverviewVisibleChanged();
}

void PreferencesController::setAudioMixerVisible(bool visible)
{
    if (m_audioMixerVisible == visible)
        return;
    m_audioMixerVisible = visible;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/audioMixerVisible"), m_audioMixerVisible);
    emit audioMixerVisibleChanged();
}

void PreferencesController::setAudioMixerWidth(qreal width)
{
    width = width > 0 ? qBound(160.0, qreal(qRound(width)), 2000.0) : 0.0;
    if (qFuzzyCompare(m_audioMixerWidth + 1, width + 1))
        return;
    m_audioMixerWidth = width;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/audioMixerWidth"), m_audioMixerWidth);
    emit audioMixerWidthChanged();
}

void PreferencesController::setTrackLabelsWidth(qreal width)
{
    width = qBound(110.0, qreal(qRound(width)), 320.0);
    if (qFuzzyCompare(m_trackLabelsWidth, width))
        return;
    m_trackLabelsWidth = width;
    QSettings settings;
    settings.setValue(QStringLiteral("ui/trackLabelsWidth"), m_trackLabelsWidth);
    emit trackLabelsWidthChanged();
}

void PreferencesController::setProxyNamePatterns(const QStringList &patterns)
{
    QStringList clean;
    for (const QString &pattern : patterns) {
        if (drift::proxyRuleFromString(pattern) && !clean.contains(pattern))
            clean.append(pattern);
    }
    if (clean == m_proxyNamePatterns)
        return;
    m_proxyNamePatterns = clean;
    QSettings().setValue(QStringLiteral("proxy/namePatterns"), clean);
    emit proxyNamePatternsChanged();
}

void PreferencesController::addProxyNamePattern(const QString &pattern)
{
    if (m_proxyNamePatterns.contains(pattern))
        return;
    setProxyNamePatterns(m_proxyNamePatterns + QStringList{pattern});
}

void PreferencesController::resetProxyNamePatterns()
{
    const QStringList defaults = drift::defaultProxyNamePatterns();
    if (m_proxyNamePatterns == defaults)
        return;
    m_proxyNamePatterns = defaults;
    QSettings().remove(QStringLiteral("proxy/namePatterns"));
    emit proxyNamePatternsChanged();
}

void PreferencesController::setTimelineToolbarLayout(const QStringList &toolbarItems,
                                                     const QStringList &menuItems)
{
    if (m_timelineToolbarItems == toolbarItems && m_timelineMenuItems == menuItems)
        return;
    m_timelineToolbarItems = toolbarItems;
    m_timelineMenuItems = menuItems;
    QSettings settings;
    if (toolbarItems.isEmpty() && menuItems.isEmpty()) {
        settings.remove(QStringLiteral("ui/timelineToolbarItems"));
        settings.remove(QStringLiteral("ui/timelineMenuItems"));
    } else {
        settings.setValue(QStringLiteral("ui/timelineToolbarItems"), toolbarItems);
        settings.setValue(QStringLiteral("ui/timelineMenuItems"), menuItems);
    }
    emit timelineToolbarLayoutChanged();
}

void PreferencesController::setReopenLastProject(bool enabled)
{
    if (m_reopenLastProject == enabled)
        return;
    m_reopenLastProject = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("editor/reopenLastProject"), m_reopenLastProject);
    emit reopenLastProjectChanged();
}

void PreferencesController::setVaapiZeroCopy(bool enabled)
{
    if (m_vaapiZeroCopy == enabled)
        return;
    m_vaapiZeroCopy = enabled;
    QSettings settings;
#if defined(Q_OS_WIN)
    settings.setValue(QStringLiteral("preview/d3d11ZeroCopy"), m_vaapiZeroCopy);
#else
    settings.setValue(QStringLiteral("preview/vaapiZeroCopy"), m_vaapiZeroCopy);
#endif
    emit vaapiZeroCopyChanged();
    emit restartNoticeRequested(tr("Faster preview takes effect after you restart Drift."));
}

void PreferencesController::setMediaCodecZeroCopy(bool enabled)
{
    if (m_mediaCodecZeroCopy == enabled)
        return;
    m_mediaCodecZeroCopy = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("preview/mediaCodecZeroCopy"), m_mediaCodecZeroCopy);
    emit mediaCodecZeroCopyChanged();
    // ClipReader reads the setting once and latches it, so a restart is not just conservative
    // advice here — the running process really will not change behaviour.
    emit restartNoticeRequested(tr("Faster preview takes effect after you restart Drift."));
}

bool PreferencesController::mediaCodecZeroCopySupported() const
{
#if defined(Q_OS_ANDROID)
    return drift::hwaccel::availableDecodeBackends().contains(drift::hwaccel::Backend::MediaCodec);
#else
    return false;
#endif
}

bool PreferencesController::vaapiZeroCopySupported() const
{
#if defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)
    return drift::hwaccel::availableDecodeBackends().contains(drift::hwaccel::Backend::Vaapi);
#elif defined(Q_OS_WIN)
    return drift::hwaccel::availableDecodeBackends().contains(drift::hwaccel::Backend::D3d11va);
#else
    return false;
#endif
}

void PreferencesController::setPreferredGpu(const QString &id)
{
    const drift::gpu::Preference preference = drift::gpu::preferenceFromId(id);
    const QString normalized = drift::gpu::preferenceId(preference);
    if (m_preferredGpu == normalized)
        return;
    m_preferredGpu = normalized;
    drift::gpu::storePreference(preference);
    emit preferredGpuChanged();
    // Not conservative advice: the driver chose this process's GPU when it loaded.
    emit restartNoticeRequested(tr("The graphics card choice takes effect after you restart Drift."));
}

bool PreferencesController::gpuPreferenceSupported() const
{
    return drift::gpu::preferenceSupported();
}

bool PreferencesController::gpuPreferenceInSystemSettings() const
{
    return drift::gpu::multipleAdapters() && drift::gpu::packagedApp();
}

void PreferencesController::setInvertTimelineScroll(bool enabled)
{
    if (m_invertTimelineScroll == enabled)
        return;
    m_invertTimelineScroll = enabled;
    QSettings settings;
    settings.setValue(QStringLiteral("timeline/invertScroll"), m_invertTimelineScroll);
    emit invertTimelineScrollChanged();
}

void PreferencesController::installUiTranslators()
{
    QCoreApplication *app = QCoreApplication::instance();
    if (!app)
        return;

    app->removeTranslator(&g_appTranslator);
    app->removeTranslator(&g_qtTranslator);

    const QLocale locale = uiLocaleFromStored();
    QLocale::setDefault(locale);
    QGuiApplication::setLayoutDirection(locale.textDirection());

    const QString translationsDir = QLibraryInfo::path(QLibraryInfo::TranslationsPath);
    if (g_qtTranslator.load(locale, QStringLiteral("qtbase"), QStringLiteral("_"), translationsDir))
        app->installTranslator(&g_qtTranslator);

    if (locale.language() == QLocale::English)
        return;

    if (g_appTranslator.load(locale, QStringLiteral("drift"), QStringLiteral("_"), QStringLiteral(":/i18n")))
        app->installTranslator(&g_appTranslator);
}

QVariantList PreferencesController::uiLanguages() const
{
    QVariantList languages;

    QVariantMap system;
    system.insert(QStringLiteral("id"), QString());
    system.insert(QStringLiteral("label"), tr("System default"));
    languages.append(system);

    QVariantMap english;
    english.insert(QStringLiteral("id"), QStringLiteral("en"));
    english.insert(QStringLiteral("label"), languageLabel(QStringLiteral("en")));
    languages.append(english);

    QStringList codes;
    const QDir dir(QStringLiteral(":/i18n"));
    const QStringList files = dir.entryList({QStringLiteral("drift_*.qm")}, QDir::Files);
    for (const QString &file : files) {
        if (!file.startsWith(QStringLiteral("drift_")) || !file.endsWith(QStringLiteral(".qm")))
            continue;
        const QString code = file.mid(6, file.size() - 9); // strip drift_ and .qm
        if (code.isEmpty() || code.compare(QStringLiteral("en"), Qt::CaseInsensitive) == 0)
            continue;
        if (!codes.contains(code))
            codes.append(code);
    }
    codes.sort(Qt::CaseInsensitive);
    for (const QString &code : codes) {
        QVariantMap entry;
        entry.insert(QStringLiteral("id"), code);
        entry.insert(QStringLiteral("label"), languageLabel(code));
        languages.append(entry);
    }
    return languages;
}

void PreferencesController::setUiLanguage(const QString &language)
{
    const QString normalized = language.trimmed();
    const bool alreadyChosen = storedUiLanguageChosen();
    if (m_uiLanguage == normalized && alreadyChosen && !m_needsUiLanguagePrompt)
        return;
    m_uiLanguage = normalized;
    QSettings settings;
    if (m_uiLanguage.isEmpty())
        settings.remove(QStringLiteral("ui/language"));
    else
        settings.setValue(QStringLiteral("ui/language"), m_uiLanguage);
    markUiLanguageChosen();
    m_needsUiLanguagePrompt = false;
    installUiTranslators();
    emit uiLanguageChanged();
}

void PreferencesController::chooseUiLanguage(const QString &code)
{
    setUiLanguage(code);
}

double PreferencesController::storedUiScale()
{
    const QVariant stored = QSettings().value(QStringLiteral("ui/scale"));
    if (!stored.isValid())
        return 1.0;
    bool ok = false;
    const double value = stored.toDouble(&ok);
    if (!ok)
        return 1.0;
    return normalizeUiScale(value);
}

void PreferencesController::applyStoredUiScale()
{
    // A shell or .desktop Exec=QT_SCALE_FACTOR=… stays the escape hatch.
    if (qEnvironmentVariableIsSet("QT_SCALE_FACTOR"))
        return;
    const double scale = storedUiScale();
    if (qFuzzyCompare(scale, 1.0))
        return;
    qputenv("QT_SCALE_FACTOR", QByteArray::number(scale, 'g', 4));
    g_uiScaleFromSettings = true;
}

double PreferencesController::appliedUiScale() const
{
    return appliedUiScaleFromEnvironment();
}

bool PreferencesController::uiScaleNeedsRestart() const
{
    return !qFuzzyCompare(m_uiScale, appliedUiScaleFromEnvironment());
}

void PreferencesController::setUiScale(double scale)
{
    const double normalized = normalizeUiScale(scale);
    if (qFuzzyCompare(m_uiScale, normalized))
        return;
    m_uiScale = normalized;
    QSettings settings;
    if (qFuzzyCompare(m_uiScale, 1.0))
        settings.remove(QStringLiteral("ui/scale"));
    else
        settings.setValue(QStringLiteral("ui/scale"), m_uiScale);
    emit uiScaleChanged();
}

QString PreferencesController::storedInterfaceShell()
{
    const QString value = QSettings().value(QStringLiteral("ui/shell")).toString();
    if (value == QLatin1String("desktop") || value == QLatin1String("mobile"))
        return value;
    return QStringLiteral("auto");
}

QString PreferencesController::resolveInterfaceShell(const QString &shell)
{
    if (shell == QLatin1String("desktop") || shell == QLatin1String("mobile"))
        return shell;
#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    // Tablets (smallest logical side >= 600 dp), DeX, ChromeOS and Android PCs get the desktop
    // shell; phones the touch one.
#ifdef Q_OS_ANDROID
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (context.isValid()) {
        const bool desktop = QJniObject::callStaticMethod<jboolean>(
            "org/cutwire/drift/DesktopMode", "isDesktop", "(Landroid/content/Context;)Z", context.object());
        QJniEnvironment().checkAndClearExceptions();
        if (desktop)
            return QStringLiteral("desktop");
    }
#endif
    if (const QScreen *screen = QGuiApplication::primaryScreen()) {
        const QSize size = screen->size();
        if (qMin(size.width(), size.height()) >= 600)
            return QStringLiteral("desktop");
    }
    return QStringLiteral("mobile");
#else
    return QStringLiteral("desktop");
#endif
}

void PreferencesController::setAppliedShell(const QString &shell)
{
    g_appliedShell = resolveInterfaceShell(shell);
}

QString PreferencesController::appliedShell() const
{
    return g_appliedShell.isEmpty() ? resolveInterfaceShell(QString()) : g_appliedShell;
}

bool PreferencesController::interfaceShellNeedsRestart() const
{
    return resolveInterfaceShell(m_interfaceShell) != appliedShell();
}

void PreferencesController::setInterfaceShell(const QString &shell)
{
    const QString normalized = (shell == QLatin1String("desktop") || shell == QLatin1String("mobile"))
                                       ? shell
                                       : QStringLiteral("auto");
    if (m_interfaceShell == normalized)
        return;
    m_interfaceShell = normalized;
    QSettings settings;
    if (m_interfaceShell == QLatin1String("auto"))
        settings.remove(QStringLiteral("ui/shell"));
    else
        settings.setValue(QStringLiteral("ui/shell"), m_interfaceShell);
    emit interfaceShellChanged();
}

bool PreferencesController::canRestart() const
{
#ifdef Q_OS_WASM
    return false;
#else
    return !qEnvironmentVariableIsSet("FLATPAK_ID");
#endif
}

QString PreferencesController::exportSettings(const QUrl &url)
{
    QSettings settings;
    QJsonObject values;
    for (const QString &key : settings.allKeys()) {
        if (isMachineOrSecretSetting(key))
            continue;
        const QVariant value = settings.value(key);
        if (value.typeId() == QMetaType::QByteArray)
            continue;
        const QJsonValue json = QJsonValue::fromVariant(value);
        if (json.isNull() || json.isUndefined())
            continue;
        values.insert(key, json);
    }

    const QJsonObject root{{QStringLiteral("drift_settings"), 1}, {QStringLiteral("values"), values}};
    const QByteArray data = QJsonDocument(root).toJson(QJsonDocument::Indented);
    std::unique_ptr<QFile> file = AndroidUri::openForWrite(url);
    if (!file || file->write(data) != data.size())
        return tr("Could not write the settings file.");
    return {};
}

QString PreferencesController::importSettings(const QUrl &url)
{
    std::unique_ptr<QFile> file = AndroidUri::openForRead(url);
    if (!file)
        return tr("Could not open the settings file.");
    QJsonParseError error;
    const QJsonObject root = QJsonDocument::fromJson(file->readAll(), &error).object();
    if (error.error != QJsonParseError::NoError
        || root.value(QStringLiteral("drift_settings")).toInt() != 1)
        return tr("That file is not a Drift settings export.");

    const QJsonObject values = root.value(QStringLiteral("values")).toObject();
    QSettings settings;
    for (auto it = values.begin(); it != values.end(); ++it) {
        if (!isMachineOrSecretSetting(it.key()))
            settings.setValue(it.key(), it.value().toVariant());
    }
    settings.sync();
    emit restartNoticeRequested(tr("Settings imported. Restart Drift to apply them all."));
    return {};
}

void PreferencesController::restartApp()
{
    if (!canRestart())
        return;
#ifdef Q_OS_ANDROID
    QSettings().sync();
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    QJniObject::callStaticMethod<void>("org/cutwire/drift/AppRestart", "restart",
                                       "(Landroid/content/Context;)V", context.object());
#elif !defined(Q_OS_WASM)
    if (m_relaunchOnQuit)
        return;
    m_relaunchOnQuit = true;
    connect(qApp, &QCoreApplication::aboutToQuit, this, [] {
        // --shell= would override the preference that prompted the restart.
        QStringList args = QCoreApplication::arguments().mid(1);
        args.removeIf([](const QString &arg) { return arg.startsWith(QLatin1String("--shell=")); });
        // Inside an AppImage the binary lives in a mount that goes away with this process, and
        // the runtime's variables point at it; relaunch the image itself with them cleared.
        const QString appImage = qEnvironmentVariable("APPIMAGE");
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        if (!appImage.isEmpty()) {
            for (const char *name : {"APPIMAGE", "APPDIR", "ARGV0", "OWD", "LD_LIBRARY_PATH",
                                     "QT_PLUGIN_PATH", "QML2_IMPORT_PATH", "QML_IMPORT_PATH",
                                     "QT_QPA_PLATFORM_PLUGIN_PATH"})
                env.remove(QString::fromLatin1(name));
        }
        // Otherwise the child would take this run's scale as an explicit override and ignore a
        // ui/scale change made in the same session.
        if (g_uiScaleFromSettings)
            env.remove(QStringLiteral("QT_SCALE_FACTOR"));
        QProcess process;
        process.setProgram(appImage.isEmpty() ? QCoreApplication::applicationFilePath() : appImage);
        process.setArguments(args);
        process.setProcessEnvironment(env);
        process.startDetached();
    });
#endif
}
