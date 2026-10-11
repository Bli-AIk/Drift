#include "SkiaFonts.h"

#include "include/core/SkString.h"

#include <QDir>
#include <QSet>
#include <QStandardPaths>
#include <QString>

#include <algorithm>
#include <mutex>

#if defined(SK_FONTMGR_FONTCONFIG_AVAILABLE)
#include "include/ports/SkFontMgr_fontconfig.h"
#include "include/ports/SkFontScanner_FreeType.h"
#elif defined(SK_FONTMGR_ANDROID_AVAILABLE)
#include "include/ports/SkFontMgr_android.h"
#include "include/ports/SkFontScanner_FreeType.h"
#elif defined(SK_FONTMGR_CORETEXT_AVAILABLE)
#include "include/ports/SkFontMgr_mac_ct.h"
#elif defined(SK_FONTMGR_FREETYPE_DIRECTORY_AVAILABLE)
#include "include/ports/SkFontMgr_directory.h"
#include "include/core/SkFontStyle.h"
#include "include/core/SkStream.h"
#include "include/core/SkTypeface.h"
#endif
#if defined(SK_FONTMGR_FREETYPE_EMPTY_AVAILABLE)
#include "include/ports/SkFontMgr_empty.h"
#endif

namespace drift::skia {

namespace {

#if !defined(SK_FONTMGR_FONTCONFIG_AVAILABLE) && !defined(SK_FONTMGR_ANDROID_AVAILABLE) \
    && !defined(SK_FONTMGR_CORETEXT_AVAILABLE) && defined(SK_FONTMGR_FREETYPE_DIRECTORY_AVAILABLE)

// Builds without a platform font port (no fontconfig, CoreText or DirectWrite in the Skia
// archive) scan the standard font folders instead. The directory manager takes one folder, and
// the paragraph fallback only consults a single default manager, so several are merged here.
QStringList systemFontDirs()
{
    QStringList candidates;
#if defined(Q_OS_MACOS)
    candidates << QStringLiteral("/System/Library/Fonts") << QStringLiteral("/Library/Fonts")
               << QDir::home().filePath(QStringLiteral("Library/Fonts"));
#elif defined(Q_OS_WIN)
    const QString windir = qEnvironmentVariable("WINDIR", QStringLiteral("C:/Windows"));
    candidates << QDir(windir).filePath(QStringLiteral("Fonts"));
    const QString local = qEnvironmentVariable("LOCALAPPDATA");
    if (!local.isEmpty())
        candidates << QDir(local).filePath(QStringLiteral("Microsoft/Windows/Fonts"));
#endif
    QStringList existing;
    for (const QString &dir : candidates) {
        if (QDir(dir).exists())
            existing << dir;
    }
    return existing;
}

class MergedFontStyleSet final : public SkFontStyleSet
{
public:
    explicit MergedFontStyleSet(QList<sk_sp<SkFontStyleSet>> sets) : m_sets(std::move(sets)) {}

    int count() override
    {
        int total = 0;
        for (auto &set : m_sets)
            total += set->count();
        return total;
    }
    void getStyle(int index, SkFontStyle *style, SkString *name) override
    {
        for (auto &set : m_sets) {
            if (index < set->count())
                return set->getStyle(index, style, name);
            index -= set->count();
        }
    }
    sk_sp<SkTypeface> createTypeface(int index) override
    {
        for (auto &set : m_sets) {
            if (index < set->count())
                return set->createTypeface(index);
            index -= set->count();
        }
        return nullptr;
    }
    sk_sp<SkTypeface> matchStyle(const SkFontStyle &pattern) override
    {
        for (auto &set : m_sets) {
            if (set->count() > 0)
                return set->matchStyle(pattern);
        }
        return nullptr;
    }

private:
    QList<sk_sp<SkFontStyleSet>> m_sets;
};

class MergedFontMgr final : public SkFontMgr
{
public:
    explicit MergedFontMgr(QList<sk_sp<SkFontMgr>> mgrs) : m_mgrs(std::move(mgrs)) {}

protected:
    int onCountFamilies() const override
    {
        int total = 0;
        for (const auto &mgr : m_mgrs)
            total += mgr->countFamilies();
        return total;
    }
    void onGetFamilyName(int index, SkString *name) const override
    {
        for (const auto &mgr : m_mgrs) {
            if (index < mgr->countFamilies())
                return mgr->getFamilyName(index, name);
            index -= mgr->countFamilies();
        }
    }
    sk_sp<SkFontStyleSet> onCreateStyleSet(int index) const override
    {
        for (const auto &mgr : m_mgrs) {
            if (index < mgr->countFamilies())
                return mgr->createStyleSet(index);
            index -= mgr->countFamilies();
        }
        return nullptr;
    }
    sk_sp<SkFontStyleSet> onMatchFamily(const char familyName[]) const override
    {
        QList<sk_sp<SkFontStyleSet>> sets;
        for (const auto &mgr : m_mgrs) {
            sk_sp<SkFontStyleSet> set = mgr->matchFamily(familyName);
            if (set && set->count() > 0)
                sets.append(set);
        }
        if (sets.isEmpty())
            return nullptr;
        return sk_make_sp<MergedFontStyleSet>(std::move(sets));
    }
    sk_sp<SkTypeface> onMatchFamilyStyle(const char familyName[], const SkFontStyle &style) const override
    {
        for (const auto &mgr : m_mgrs) {
            if (sk_sp<SkTypeface> face = mgr->matchFamilyStyle(familyName, style))
                return face;
        }
        return nullptr;
    }
    sk_sp<SkTypeface> onMatchFamilyStyleCharacter(const char familyName[], const SkFontStyle &style,
                                                  const char *bcp47[], int bcp47Count,
                                                  SkUnichar character) const override
    {
        for (const auto &mgr : m_mgrs) {
            if (sk_sp<SkTypeface> face = mgr->matchFamilyStyleCharacter(familyName, style, bcp47, bcp47Count, character))
                return face;
        }
        return nullptr;
    }
    sk_sp<SkTypeface> onMakeFromData(sk_sp<SkData> data, int ttcIndex) const override
    {
        return m_mgrs.first()->makeFromData(std::move(data), ttcIndex);
    }
    sk_sp<SkTypeface> onMakeFromStreamIndex(std::unique_ptr<SkStreamAsset> stream, int ttcIndex) const override
    {
        return m_mgrs.first()->makeFromStream(std::move(stream), ttcIndex);
    }
    sk_sp<SkTypeface> onMakeFromStreamArgs(std::unique_ptr<SkStreamAsset> stream,
                                           const SkFontArguments &args) const override
    {
        return m_mgrs.first()->makeFromStream(std::move(stream), args);
    }
    sk_sp<SkTypeface> onMakeFromFile(const char path[], int ttcIndex) const override
    {
        return m_mgrs.first()->makeFromFile(path, ttcIndex);
    }
    sk_sp<SkTypeface> onLegacyMakeTypeface(const char familyName[], SkFontStyle style) const override
    {
        for (const auto &mgr : m_mgrs) {
            if (sk_sp<SkTypeface> face = mgr->legacyMakeTypeface(familyName, style))
                return face;
        }
        return nullptr;
    }

private:
    QList<sk_sp<SkFontMgr>> m_mgrs;
};

sk_sp<SkFontMgr> makeDirectoryMgr()
{
    QList<sk_sp<SkFontMgr>> mgrs;
    for (const QString &dir : systemFontDirs()) {
        if (sk_sp<SkFontMgr> mgr = SkFontMgr_New_Custom_Directory(QDir::toNativeSeparators(dir).toUtf8().constData()))
            mgrs.append(mgr);
    }
    if (mgrs.isEmpty())
        return nullptr;
    if (mgrs.size() == 1)
        return mgrs.first();
    return sk_make_sp<MergedFontMgr>(std::move(mgrs));
}

#endif

} // namespace

sk_sp<SkFontMgr> systemFontMgr()
{
    static sk_sp<SkFontMgr> mgr;
    static std::once_flag once;
    std::call_once(once, [] {
#if defined(SK_FONTMGR_FONTCONFIG_AVAILABLE)
        mgr = SkFontMgr_New_FontConfig(nullptr, SkFontScanner_Make_FreeType());
#elif defined(SK_FONTMGR_ANDROID_AVAILABLE)
        mgr = SkFontMgr_New_Android(nullptr, SkFontScanner_Make_FreeType());
#elif defined(SK_FONTMGR_CORETEXT_AVAILABLE)
        mgr = SkFontMgr_New_CoreText(nullptr);
#elif defined(SK_FONTMGR_FREETYPE_DIRECTORY_AVAILABLE)
        mgr = makeDirectoryMgr();
#endif
#if defined(SK_FONTMGR_FREETYPE_EMPTY_AVAILABLE) && !defined(SK_FONTMGR_FONTCONFIG_AVAILABLE) \
    && !defined(SK_FONTMGR_ANDROID_AVAILABLE) && !defined(SK_FONTMGR_CORETEXT_AVAILABLE)
        if (!mgr)
            mgr = SkFontMgr_New_Custom_Empty();
#endif
        if (!mgr)
            mgr = SkFontMgr::RefEmpty();
    });
    return mgr;
}

QStringList systemFontFamilies()
{
    static QStringList families;
    static std::once_flag once;
    std::call_once(once, [] {
        const sk_sp<SkFontMgr> mgr = systemFontMgr();
        QSet<QString> seen;
        const int count = mgr->countFamilies();
        for (int i = 0; i < count; ++i) {
            SkString name;
            mgr->getFamilyName(i, &name);
            const QString family = QString::fromUtf8(name.c_str()).trimmed();
            // Dotted names are macOS/Android internals (".SF NS", ".Helvetica Neue DeskInterface").
            if (family.isEmpty() || family.startsWith(QLatin1Char('.')) || seen.contains(family))
                continue;
            seen.insert(family);
            families.append(family);
        }
        std::sort(families.begin(), families.end(), [](const QString &a, const QString &b) {
            return a.compare(b, Qt::CaseInsensitive) < 0;
        });
    });
    return families;
}

} // namespace drift::skia
