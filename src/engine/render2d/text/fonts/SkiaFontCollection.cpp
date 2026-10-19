#include "engine/render2d/text/fonts/SkiaFontCollection.h"

#include "engine/render2d/text/fonts/SkiaFonts.h"

#include <QList>
#include <QString>

#include "include/core/SkData.h"
#include "include/core/SkFontMgr.h"
#include "modules/skparagraph/include/TypefaceFontProvider.h"

namespace drift::skia {

namespace {

struct Entry
{
    QString alias;
    QString path;
    sk_sp<SkTypeface> typeface;
};

QList<Entry> g_entries[3];
sk_sp<::skia::textlayout::TypefaceFontProvider> g_provider;
sk_sp<::skia::textlayout::FontCollection> g_collection;

void applyProvider()
{
    g_provider = sk_make_sp<::skia::textlayout::TypefaceFontProvider>();
    for (const QList<Entry> &group : g_entries) {
        for (const Entry &entry : group)
            g_provider->registerTypeface(entry.typeface, SkString(entry.alias.toUtf8().constData()));
    }
    if (g_collection) {
        g_collection->setAssetFontManager(g_provider);
        g_collection->clearCaches();
    }
}

} // namespace

std::recursive_mutex &textLayoutMutex()
{
    static std::recursive_mutex mutex;
    return mutex;
}

void registerFontFile(FontGroup group, const QString &path, const QString &alias)
{
    std::lock_guard lock(textLayoutMutex());
    sk_sp<SkTypeface> typeface = systemFontMgr()->makeFromFile(path.toUtf8().constData());
    if (!typeface)
        return;
    g_entries[int(group)].append({alias, path, typeface});
    if (g_provider)
        g_provider->registerTypeface(typeface, SkString(alias.toUtf8().constData()));
    if (g_collection)
        g_collection->clearCaches();
}

QStringList registerFontFaces(FontGroup group, const QString &path)
{
    std::lock_guard lock(textLayoutMutex());
    QStringList families;
    const QByteArray utf8 = path.toUtf8();
    // A collection has no face count in this API; the index past the last face yields null.
    for (int index = 0; index < 256; ++index) {
        sk_sp<SkTypeface> typeface = systemFontMgr()->makeFromFile(utf8.constData(), index);
        if (!typeface)
            break;
        SkString name;
        typeface->getFamilyName(&name);
        const QString alias = QString::fromUtf8(name.c_str());
        g_entries[int(group)].append({alias, path, typeface});
        if (g_provider)
            g_provider->registerTypeface(typeface, name);
        if (!families.contains(alias))
            families.append(alias);
    }
    if (g_collection)
        g_collection->clearCaches();
    return families;
}

void unregisterFontFile(FontGroup group, const QString &path)
{
    std::lock_guard lock(textLayoutMutex());
    QList<Entry> &entries = g_entries[int(group)];
    entries.removeIf([&](const Entry &entry) { return entry.path == path; });
    applyProvider();
}

void clearRegisteredFonts(FontGroup group)
{
    std::lock_guard lock(textLayoutMutex());
    g_entries[int(group)].clear();
    applyProvider();
}

sk_sp<SkTypeface> registeredTypeface(const QString &alias)
{
    std::lock_guard lock(textLayoutMutex());
    for (const QList<Entry> &group : g_entries) {
        for (const Entry &entry : group) {
            if (entry.alias == alias)
                return entry.typeface;
        }
    }
    return nullptr;
}

sk_sp<::skia::textlayout::FontCollection> textFontCollection()
{
    std::lock_guard lock(textLayoutMutex());
    if (!g_collection) {
        g_collection = sk_make_sp<::skia::textlayout::FontCollection>();
        g_collection->setDefaultFontManager(systemFontMgr());
        g_collection->enableFontFallback();
        applyProvider();
    }
    return g_collection;
}

} // namespace drift::skia
