#include "engine/FontCatalog.h"

#include "engine/GpuPackageParse.h"
#ifdef DRIFT_WITH_SKIA
#include "engine/SkiaFontCollection.h"
#include "engine/SkiaFonts.h"
#endif

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFontDatabase>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMutex>
#include <QMutexLocker>
#include <QStandardPaths>

#include <algorithm>
#include <cstdlib>
#include <limits>

QList<int> FontFamilyEntry::weights() const
{
    QList<int> out;
    for (const FontFace &face : faces) {
        if (!face.italic && !out.contains(face.weight))
            out.append(face.weight);
    }
    std::sort(out.begin(), out.end());
    return out;
}

bool FontFamilyEntry::hasItalic() const
{
    for (const FontFace &face : faces) {
        if (face.italic)
            return true;
    }
    return false;
}

namespace {

QList<FontFamilyEntry> g_catalog;
QHash<QString, int> g_familyIndex; // lowercased family name -> index
QMutex g_mutex;
bool g_initialized = false;

FontFamilyEntry loadPackage(const QString &packageDir)
{
    FontFamilyEntry entry;

    QFile file(QDir(packageDir).filePath(QStringLiteral("family.json")));
    if (!file.open(QIODevice::ReadOnly))
        return entry;

    const QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();
    if (root.isEmpty())
        return entry;

    entry.id = root.value(QStringLiteral("id")).toString();
    entry.family = root.value(QStringLiteral("family")).toString();
    entry.category = root.value(QStringLiteral("category")).toString();
    entry.license = root.value(QStringLiteral("license")).toString();
    entry.order = root.value(QStringLiteral("order")).toInt();
    entry.packageDir = packageDir;
    if (entry.family.isEmpty())
        return {};

    const QJsonArray faces = root.value(QStringLiteral("faces")).toArray();
    for (const QJsonValue &value : faces) {
        const QJsonObject object = value.toObject();
        const QString relative = object.value(QStringLiteral("file")).toString();
        const QString absolute = QDir(packageDir).filePath(relative);
        if (relative.isEmpty() || !QFile::exists(absolute))
            continue;

        const int id = QFontDatabase::addApplicationFont(absolute);
        if (id < 0) {
            qWarning("FontCatalog: Qt rejected %s", qPrintable(absolute));
            continue;
        }
        if (entry.qtFamily.isEmpty())
            entry.qtFamily = QFontDatabase::applicationFontFamilies(id).value(0);
#ifdef DRIFT_WITH_SKIA
        // Keyed by file: the weight inside these files is unreliable (see fontForStyle), so the
        // layout names the exact face rather than letting Skia match on a family and a weight.
        drift::skia::registerFontFile(drift::skia::FontGroup::Catalog, absolute, absolute);
#endif

        FontFace face;
        face.weight = qBound(100, object.value(QStringLiteral("weight")).toInt(400), 900);
        face.italic = object.value(QStringLiteral("italic")).toBool();
        face.styleName = object.value(QStringLiteral("styleName")).toString();
        face.file = absolute;
        entry.faces.append(face);
    }

    if (entry.faces.isEmpty() || entry.qtFamily.isEmpty())
        return {};

    std::sort(entry.faces.begin(), entry.faces.end(), [](const FontFace &a, const FontFace &b) {
        if (a.weight != b.weight)
            return a.weight < b.weight;
        return !a.italic && b.italic;
    });
    return entry;
}

void rebuildLocked(const QStringList &packageRoots)
{
    g_catalog.clear();
    g_familyIndex.clear();
#ifdef DRIFT_WITH_SKIA
    drift::skia::clearRegisteredFonts(drift::skia::FontGroup::Catalog);
#endif

    const QStringList roots = packageRoots.isEmpty()
        ? GpuPackageParse::defaultSearchPaths(QStringLiteral("DRIFT_FONTS_DIR"),
                                              QStringLiteral("fonts"), QStringLiteral("fonts"))
        : packageRoots;

    for (const QString &root : roots) {
        QDir dir(root);
        if (!dir.exists())
            continue;
        const QStringList packages = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const QString &package : packages) {
            FontFamilyEntry entry = loadPackage(dir.filePath(package));
            if (entry.family.isEmpty())
                continue;
            // First root wins, so DRIFT_FONTS_DIR can shadow the shipped bundle.
            if (g_familyIndex.contains(entry.family.toLower()))
                continue;
            g_familyIndex.insert(entry.family.toLower(), g_catalog.size());
            g_catalog.append(entry);
        }
    }

    std::sort(g_catalog.begin(), g_catalog.end(), [](const FontFamilyEntry &a, const FontFamilyEntry &b) {
        if (a.category != b.category)
            return a.category < b.category;
        if (a.order != b.order)
            return a.order < b.order;
        return a.family < b.family;
    });

    g_familyIndex.clear();
    for (int i = 0; i < g_catalog.size(); ++i)
        g_familyIndex.insert(g_catalog.at(i).family.toLower(), i);

    g_initialized = true;
}

void ensureLocked()
{
    if (!g_initialized)
        rebuildLocked({});
}

// CSS-style nearest weight: at or above 400 prefer the next heavier face, below 400 the next
// lighter one, and fall back to whatever is closest when the family runs out in that direction.
const FontFace *nearestFace(const FontFamilyEntry &entry, int weight, bool italic)
{
    const FontFace *best = nullptr;
    int bestScore = std::numeric_limits<int>::max();

    for (const FontFace &face : entry.faces) {
        if (face.italic != italic)
            continue;
        const int distance = std::abs(face.weight - weight);
        const bool wrongSide = weight >= 400 ? face.weight < weight : face.weight > weight;
        const int score = distance + (wrongSide ? 1000 : 0);
        if (score < bestScore) {
            bestScore = score;
            best = &face;
        }
    }
    return best;
}

} // namespace

void reloadFontCatalog(const QStringList &packageRoots)
{
    QMutexLocker lock(&g_mutex);
    rebuildLocked(packageRoots);
}

const QList<FontFamilyEntry> &fontCatalog()
{
    QMutexLocker lock(&g_mutex);
    ensureLocked();
    return g_catalog;
}

const FontFamilyEntry *fontFamilyForName(const QString &family)
{
    QMutexLocker lock(&g_mutex);
    ensureLocked();
    const auto it = g_familyIndex.constFind(family.toLower());
    if (it == g_familyIndex.constEnd())
        return nullptr;
    return &g_catalog.at(it.value());
}

namespace {

struct UserFont
{
    QString path;
    QStringList families;
    int qtId = -1;
};

QList<UserFont> g_userFonts;
QMutex g_userMutex;

bool isFontFile(const QString &path)
{
    static const QStringList suffixes = {QStringLiteral("ttf"), QStringLiteral("otf"), QStringLiteral("ttc"),
                                         QStringLiteral("otc")};
    return suffixes.contains(QFileInfo(path).suffix().toLower());
}

// Registers one stored file with Qt and Skia. Empty families means neither could read it.
bool registerUserFile(const QString &path, QStringList *families, int *qtId)
{
    *qtId = QFontDatabase::addApplicationFont(path);
    if (*qtId < 0)
        return false;
    *families = QFontDatabase::applicationFontFamilies(*qtId);
#ifdef DRIFT_WITH_SKIA
    // Skia's own family names are what the layout asks for, and they can differ from Qt's.
    const QStringList skia = drift::skia::registerFontFaces(drift::skia::FontGroup::User, path);
    if (skia.isEmpty()) {
        QFontDatabase::removeApplicationFont(*qtId);
        return false;
    }
    *families = skia;
#endif
    return !families->isEmpty();
}

} // namespace

QString userFontDir()
{
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (base.isEmpty())
        return {};
    return QDir(base).filePath(QStringLiteral("fonts/user"));
}

void reloadUserFonts()
{
    QMutexLocker lock(&g_userMutex);
    for (const UserFont &font : g_userFonts) {
        QFontDatabase::removeApplicationFont(font.qtId);
#ifdef DRIFT_WITH_SKIA
        drift::skia::unregisterFontFile(drift::skia::FontGroup::User, font.path);
#endif
    }
    g_userFonts.clear();

    const QDir dir(userFontDir());
    for (const QString &name : dir.entryList(QDir::Files, QDir::Name)) {
        const QString path = dir.filePath(name);
        UserFont font;
        font.path = path;
        if (isFontFile(path) && registerUserFile(path, &font.families, &font.qtId))
            g_userFonts.append(font);
        else
            qWarning("FontCatalog: could not load user font %s", qPrintable(path));
    }
}

QStringList importUserFontFile(const QString &path, QString *error)
{
    auto fail = [&](const QString &message) {
        if (error)
            *error = message;
        return QStringList();
    };

    if (!isFontFile(path))
        return fail(QCoreApplication::translate("FontCatalog", "Choose a .ttf, .otf or .ttc font file"));
    const QString dirPath = userFontDir();
    if (dirPath.isEmpty() || !QDir().mkpath(dirPath))
        return fail(QCoreApplication::translate("FontCatalog", "Could not create the fonts folder"));

    const QFileInfo source(path);
    const QDir dir(dirPath);
    QString target = dir.filePath(source.fileName());
    for (int n = 2; QFile::exists(target); ++n)
        target = dir.filePath(QStringLiteral("%1-%2.%3").arg(source.completeBaseName()).arg(n).arg(source.suffix()));
    if (!QFile::copy(path, target))
        return fail(QCoreApplication::translate("FontCatalog", "Could not copy the font file"));

    UserFont font;
    font.path = target;
    if (!registerUserFile(target, &font.families, &font.qtId)) {
        QFile::remove(target);
        return fail(QCoreApplication::translate("FontCatalog", "That file is not a usable font"));
    }
    QMutexLocker lock(&g_userMutex);
    g_userFonts.append(font);
    return font.families;
}

bool removeUserFont(const QString &family)
{
    QMutexLocker lock(&g_userMutex);
    bool removed = false;
    for (int i = g_userFonts.size() - 1; i >= 0; --i) {
        const UserFont &font = g_userFonts.at(i);
        if (!font.families.contains(family))
            continue;
        QFontDatabase::removeApplicationFont(font.qtId);
#ifdef DRIFT_WITH_SKIA
        drift::skia::unregisterFontFile(drift::skia::FontGroup::User, font.path);
#endif
        QFile::remove(font.path);
        g_userFonts.removeAt(i);
        removed = true;
    }
    return removed;
}

QStringList systemFontFamilies()
{
#ifdef DRIFT_WITH_SKIA
    return drift::skia::systemFontFamilies();
#else
    return QFontDatabase::families();
#endif
}

QStringList userFontFamilies()
{
    QMutexLocker lock(&g_userMutex);
    QStringList out;
    for (const UserFont &font : g_userFonts) {
        for (const QString &family : font.families) {
            if (!out.contains(family))
                out.append(family);
        }
    }
    out.sort(Qt::CaseInsensitive);
    return out;
}

QList<QPair<QString, QString>> fontCategories()
{
    return {
        {QStringLiteral("impact"), QCoreApplication::translate("FontCatalog", "High-Impact & Bold")},
        {QStringLiteral("clean"), QCoreApplication::translate("FontCatalog", "Clean & Minimal")},
        {QStringLiteral("editorial"), QCoreApplication::translate("FontCatalog", "Classy & Editorial")},
        {QStringLiteral("playful"), QCoreApplication::translate("FontCatalog", "Creative & Playful")},
    };
}

namespace {

const FontFace *faceForStyle(const FontFamilyEntry &entry, const drift::TextStyle &style)
{
    const FontFace *face = nearestFace(entry, style.fontWeight, style.italic);
    if (!face && style.italic) // family ships no italic; use the upright face
        face = nearestFace(entry, style.fontWeight, false);
    if (!face)
        face = &entry.faces.first();
    return face;
}

} // namespace

ResolvedFont resolveFont(const drift::TextStyle &style)
{
    const FontFamilyEntry *entry = fontFamilyForName(style.fontFamily);
    if (!entry)
        return {style.fontFamily, qBound(100, style.fontWeight, 900), style.italic, false};
    const FontFace *face = faceForStyle(*entry, style);
    return {face->file, face->weight, face->italic, true};
}

QFont fontForStyle(const drift::TextStyle &style, int pixelSizePx)
{
    const int px = qMax(4, pixelSizePx);
    const FontFamilyEntry *entry = fontFamilyForName(style.fontFamily);

    if (!entry) { // not in the bundle — let the system font database resolve it
        QFont font(style.fontFamily);
        font.setPixelSize(px);
        font.setWeight(QFont::Weight(qBound(100, style.fontWeight, 900)));
        font.setItalic(style.italic);
        return font;
    }

    const FontFace *face = faceForStyle(*entry, style);

    QFont font(entry->qtFamily);
    // usWeightClass is unreliable in these files (Montserrat/Inter Thin both report 250), so the
    // style name is what actually pins the face; the weight is a hint for backends that ignore it.
    font.setStyleName(face->styleName);
    font.setWeight(QFont::Weight(face->weight));
    font.setItalic(face->italic);
    font.setPixelSize(px);
    return font;
}
