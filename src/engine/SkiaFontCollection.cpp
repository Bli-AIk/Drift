#include "SkiaFontCollection.h"

#include "SkiaFonts.h"

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
    sk_sp<SkTypeface> typeface;
};

QList<Entry> g_entries[2];
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
    g_entries[int(group)].append({alias, typeface});
    if (g_provider)
        g_provider->registerTypeface(typeface, SkString(alias.toUtf8().constData()));
    if (g_collection)
        g_collection->clearCaches();
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
