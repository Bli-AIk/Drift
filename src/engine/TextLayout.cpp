#include "TextLayout.h"

#include "EmojiCatalog.h"
#include "FontCatalog.h"
#ifdef DRIFT_WITH_SKIA
#include "SkiaFontCollection.h"
#include "SkiaFonts.h"
#include "SkiaTextGeometry.h"

#include "include/core/SkFontMetrics.h"
#include "include/core/SkFontMgr.h"
#include "include/core/SkPathBuilder.h"
#include "modules/skparagraph/include/Paragraph.h"
#include "modules/skparagraph/include/ParagraphBuilder.h"
#include "modules/skparagraph/include/ParagraphStyle.h"
#include "modules/skparagraph/include/TextStyle.h"
#include "modules/skunicode/include/SkUnicode_icu.h"
#endif

#include <QCache>
#include <QMutex>
#include <QMutexLocker>
#include <QTextBoundaryFinder>
#include <QtMath>

#include <algorithm>
#include <cmath>
#include <limits>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

namespace drift::text {

static quint64 highlightHash(const drift::TextHighlight &h)
{
    return qHashMulti(0, h.enabled, h.color.rgba(), h.padding, h.radius);
}

// Everything about a style that changes pixels.
quint64 styleHash(const drift::TextStyle &s)
{
    // Deliberately excludes the animation and the time: motion is applied per fragment at draw
    // time, so the laid-out pieces serve every frame.
    const drift::WordAccent &a = s.accent;
    return qHashMulti(0, s.fontFamily, s.pixelSize, s.fontWeight, s.italic, drift::textLayersHash(s.layers),
                      s.pathBend, static_cast<int>(s.align), static_cast<int>(s.valign), s.wordWrap,
                      s.lineHeight, s.letterSpacing, s.boxEnabled, s.boxColor.rgba(), s.boxPadding,
                      s.boxRadius, highlightHash(s.wordHighlight), s.underlineEnabled,
                      s.underlineColor.rgba(), s.underlineWidth, s.underlineOffset,
                      qHashMulti(0, static_cast<int>(a.rule), a.n, a.phase, a.colorEnabled,
                                 a.color.rgba(), a.sizeScale, a.outlineEnabled, a.outlineWidth,
                                 a.outlineColor.rgba(), highlightHash(a.highlight)));
}

// Only what moves glyphs: the look (colours, strokes) is painted, not laid out.
quint64 layoutKey(const QString &text, const drift::TextStyle &s, double wrapWidth, double blockHeight,
                  double renderScale, int activeWordIndex, WordSplit split)
{
    const drift::WordAccent &a = s.accent;
    return qHashMulti(0, text, s.fontFamily, s.pixelSize, s.fontWeight, s.italic, static_cast<int>(s.align),
                      static_cast<int>(s.valign), s.wordWrap, s.lineHeight, s.letterSpacing,
                      static_cast<int>(a.rule), a.n, a.phase, a.sizeScale, qRound(wrapWidth * 4.0),
                      qRound(blockHeight * 4.0), qRound(renderScale * 1000.0), activeWordIndex,
                      static_cast<int>(split));
}

// The grapheme cluster boundaries inside [from, to), ends included. Qt's are extended clusters,
// so a ZWJ sequence, a flag or a skin-tone modifier stays in one piece.
QList<int> graphemeBoundaries(const QString &source, int from, int to)
{
    QList<int> stops{from};
    QTextBoundaryFinder finder(QTextBoundaryFinder::Grapheme, source);
    finder.setPosition(from);
    while (finder.toNextBoundary() > 0 && finder.position() < to)
        stops.append(finder.position());
    stops.append(to);
    return stops;
}

QList<WordRange> wordRanges(const QString &source)
{
    QList<WordRange> ranges;
    int i = 0;
    while (i < source.size()) {
        while (i < source.size() && source.at(i).isSpace())
            ++i;
        if (i >= source.size())
            break;
        int end = i;
        while (end < source.size() && !source.at(end).isSpace())
            ++end;
        ranges.append({i, end - i});
        i = end;
    }
    return ranges;
}

// Whether a pack's rule picks out this word. Positional rules are pure functions of the index, so
// the raster stays valid for the whole cue; Karaoke is the one rule that moves with the playhead.
static bool accentedWord(const drift::WordAccent &accent, int index, int count, int longestIndex,
                  int activeWordIndex)
{
    switch (accent.rule) {
    case drift::WordAccentRule::None:
        return false;
    case drift::WordAccentRule::FirstWord:
        return index == 0;
    case drift::WordAccentRule::LastWord:
        return index == count - 1;
    case drift::WordAccentRule::EveryOther:
        return index >= accent.phase && (index - accent.phase) % 2 == 0;
    case drift::WordAccentRule::EveryNth:
        return index >= accent.phase && (index - accent.phase) % qMax(1, accent.n) == 0;
    case drift::WordAccentRule::LongestWord:
        return index == longestIndex;
    case drift::WordAccentRule::RandomStable: {
        // Stable per-index draw so the same words stay accented across frames. ~1 word in 3.
        const quint32 h = qHash(static_cast<quint32>(index) * 2654435761u) ^ 0x9e3779b9u;
        return (h & 0xffffu) < 0x5555u;
    }
    case drift::WordAccentRule::Karaoke:
        return index == activeWordIndex;
    }
    return false;
}

#ifdef DRIFT_WITH_SKIA

namespace {

namespace skt = ::skia::textlayout;

// The text as UTF-8 for Skia, with both index maps. SkParagraph reports everything in UTF-8
// offsets; the rest of the app addresses the source QString in UTF-16.
struct Utf8Text
{
    std::string text;
    QList<int> u8At;  // UTF-16 index -> byte offset of its code point (a low surrogate shares its pair's)
    QList<int> u16At; // byte offset -> UTF-16 index of its code point; one past the end maps to size
};

void appendUtf8(std::string &out, char32_t cp)
{
    if (cp < 0x80) {
        out += char(cp);
    } else if (cp < 0x800) {
        out += char(0xC0 | (cp >> 6));
        out += char(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        out += char(0xE0 | (cp >> 12));
        out += char(0x80 | ((cp >> 6) & 0x3F));
        out += char(0x80 | (cp & 0x3F));
    } else {
        out += char(0xF0 | (cp >> 18));
        out += char(0x80 | ((cp >> 12) & 0x3F));
        out += char(0x80 | ((cp >> 6) & 0x3F));
        out += char(0x80 | (cp & 0x3F));
    }
}

Utf8Text toUtf8(const QString &source)
{
    Utf8Text out;
    const int n = source.size();
    out.u8At.resize(n + 1);
    for (int i = 0; i < n;) {
        const QChar c = source.at(i);
        char32_t cp = c.unicode();
        int units = 1;
        if (c.isHighSurrogate() && i + 1 < n && source.at(i + 1).isLowSurrogate()) {
            cp = QChar::surrogateToUcs4(c, source.at(i + 1));
            units = 2;
        } else if (c.isSurrogate()) {
            cp = 0xFFFD;
        }
        const int offset = int(out.text.size());
        for (int k = 0; k < units; ++k)
            out.u8At[i + k] = offset;
        appendUtf8(out.text, cp);
        while (out.u16At.size() < out.text.size())
            out.u16At.append(i);
        i += units;
    }
    out.u8At[n] = int(out.text.size());
    out.u16At.append(n);
    return out;
}

// Colour emoji ship as a CBDT/CBLC bitmap face, which carries no glyph outlines, so they have to
// be drawn as glyphs and the layout has to pick them out first.
//
// The codepoint ranges come first so ordinary text never probes the font, and VS-16 is in them
// because it forces emoji presentation on characters that are otherwise textual. The face's own
// cmap then has the final say: a dingbat the emoji font does not carry stays with the styled
// font rather than falling back to whatever the system offers.
bool isEmojiCluster(const QString &cluster, SkTypeface &emojiFace)
{
    const QList<uint> points = cluster.toUcs4();

    bool candidate = false;
    for (const uint point : points) {
        if (point == 0xFE0F || (point >= 0x1F000 && point <= 0x1FAFF)
            || (point >= 0x2600 && point <= 0x27BF) || (point >= 0x2B00 && point <= 0x2BFF)) {
            candidate = true;
            break;
        }
    }
    if (!candidate)
        return false;

    for (const uint point : points) {
        // Joiners, selectors and tag characters glue a sequence together and are in no cmap;
        // only the visible characters say anything about coverage.
        if (point == 0x200D || point == 0xFE0E || point == 0xFE0F
            || (point >= 0xE0020 && point <= 0xE007F))
            continue;
        if (emojiFace.unicharToGlyph(SkUnichar(point)) == 0)
            return false;
    }
    return true;
}

struct RunData
{
    int line = 0;
    SkFont font;
    float originX = 0;
    float advanceX = 0;
    std::vector<SkGlyphID> glyphs;
    std::vector<SkPoint> positions;
    std::vector<uint32_t> starts; // count + 1
};

skt::TextStyle makeTextStyle(const QString &family, int weight, bool italic, double px, double letterSpacing)
{
    skt::TextStyle style;
    style.setFontFamilies({SkString(family.toUtf8().constData())});
    style.setFontSize(float(px));
    style.setFontStyle(SkFontStyle(weight, SkFontStyle::kNormal_Width,
                                   italic ? SkFontStyle::kItalic_Slant : SkFontStyle::kUpright_Slant));
    style.setLetterSpacing(float(letterSpacing));
    return style;
}

bool rightToLeft(const QString &source)
{
    for (const uint cp : source.toUcs4()) {
        const QChar::Direction d = QChar::direction(cp);
        if (d == QChar::DirL)
            return false;
        if (d == QChar::DirR || d == QChar::DirAL)
            return true;
    }
    return false;
}

QRectF toQRect(const SkRect &r)
{
    return QRectF(r.left(), r.top(), r.width(), r.height());
}

} // namespace

TextLayoutResult layoutStyledText(const QString &text, const drift::TextStyle &style, double renderScale,
                                  double wrapWidth, double blockHeight, int activeWordIndex, WordSplit split)
{
    const QString &source = text;

    const QList<WordRange> ranges = wordRanges(source);
    if (ranges.isEmpty())
        return {};

    int longestIndex = 0;
    for (int i = 1; i < ranges.size(); ++i) {
        if (ranges.at(i).length > ranges.at(longestIndex).length)
            longestIndex = i;
    }

    QList<bool> accentFlags;
    accentFlags.reserve(ranges.size());
    for (int i = 0; i < ranges.size(); ++i)
        accentFlags.append(accentedWord(style.accent, i, ranges.size(), longestIndex, activeWordIndex));

    // Catalog lookups take the catalog's lock, so they happen before the layout lock is held:
    // the catalog registers fonts under it in the opposite order.
    const ResolvedFont resolved = resolveFont(style);
    const QString emojiFamily = emojiFontFamily();

    const double letterSpacing = qFuzzyIsNull(style.letterSpacing) ? 0.0 : style.letterSpacing * renderScale;
    const int basePx = qMax(4, qRound(style.pixelSize * renderScale));
    int accentPx = basePx;
    const double accentScale = style.accent.sizeScale;
    if (style.accent.rule != drift::WordAccentRule::None && accentScale > 0.0 && !qFuzzyCompare(accentScale, 1.0))
        accentPx = qMax(1, qRound(style.pixelSize * accentScale * renderScale));
    const bool anyAccent = std::find(accentFlags.cbegin(), accentFlags.cend(), true) != accentFlags.cend();
    const bool mixedSizes = accentPx != basePx && anyAccent;

    std::lock_guard<std::recursive_mutex> lock(drift::skia::textLayoutMutex());

    sk_sp<skt::FontCollection> collection = drift::skia::textFontCollection();
    const sk_sp<SkTypeface> emojiFace = emojiFamily.isEmpty() ? nullptr : drift::skia::registeredTypeface(emojiFamily);

    const Utf8Text utf8 = toUtf8(source);

    // Grapheme ordinal of every text position, spaces included, for the animator's character
    // domain.
    const QList<int> graphemes = graphemeBoundaries(source, 0, source.size());
    QList<int> graphemeAt(source.size() + 1, 0);
    {
        int ordinal = 0;
        for (int g = 0; g + 1 < graphemes.size(); ++g, ++ordinal)
            for (int pos = graphemes.at(g); pos < graphemes.at(g + 1); ++pos)
                graphemeAt[pos] = ordinal;
        graphemeAt[source.size()] = ordinal;
    }

    // Emoji clusters take the colour face first, whatever the styled font would do with them.
    QList<bool> emojiAt(source.size() + 1, false);
    if (emojiFace) {
        for (int g = 0; g + 1 < graphemes.size(); ++g) {
            const int cs = graphemes.at(g);
            const int ce = graphemes.at(g + 1);
            if (isEmojiCluster(source.mid(cs, ce - cs), *emojiFace)) {
                for (int p = cs; p < ce; ++p)
                    emojiAt[p] = true;
            }
        }
    }
    QList<bool> accentAt(source.size() + 1, false);
    for (int wi = 0; wi < ranges.size(); ++wi) {
        if (accentFlags.at(wi)) {
            for (int p = ranges.at(wi).start; p < ranges.at(wi).start + ranges.at(wi).length; ++p)
                accentAt[p] = true;
        }
    }

    const auto styleFor = [&](bool accent, bool emoji) {
        const double px = accent ? accentPx : basePx;
        return emoji ? makeTextStyle(emojiFamily, 400, false, px, letterSpacing)
                     : makeTextStyle(resolved.family, resolved.weight, resolved.italic, px, letterSpacing);
    };

    skt::ParagraphStyle paragraphStyle;
    paragraphStyle.setTextStyle(styleFor(false, false));
    // Alignment is applied by hand below, so it stays correct with NoWrap, where the natural text
    // can be wider than the box.
    paragraphStyle.setTextAlign(skt::TextAlign::kLeft);
    paragraphStyle.setTextDirection(rightToLeft(source) ? skt::TextDirection::kRtl : skt::TextDirection::kLtr);
    paragraphStyle.setApplyRoundingHack(false);

    static const sk_sp<SkUnicode> unicode = SkUnicodes::ICU::Make();
    std::unique_ptr<skt::ParagraphBuilder> builder = skt::ParagraphBuilder::make(paragraphStyle, collection, unicode);
    for (int start = 0; start < source.size();) {
        const bool accent = accentAt.at(start);
        const bool emoji = emojiAt.at(start);
        int end = start + 1;
        while (end < source.size() && accentAt.at(end) == accent && emojiAt.at(end) == emoji)
            ++end;
        builder->pushStyle(styleFor(accent, emoji));
        builder->addText(utf8.text.data() + utf8.u8At.at(start), size_t(utf8.u8At.at(end) - utf8.u8At.at(start)));
        builder->pop();
        start = end;
    }
    std::shared_ptr<skt::Paragraph> paragraph = builder->Build();
    paragraph->layout(style.wordWrap ? float(qMax(1.0, wrapWidth)) : 1.0e6f);

    std::vector<skt::LineMetrics> lines;
    paragraph->getLineMetrics(lines);
    const int lineCount = int(lines.size());
    if (lineCount == 0)
        return {};

    std::vector<RunData> runs;
    paragraph->visit([&](int line, const skt::Paragraph::VisitorInfo *info) {
        if (!info || info->count <= 0)
            return;
        RunData run;
        run.line = line;
        run.font = info->font;
        run.font.setHinting(SkFontHinting::kNone);
        run.font.setSubpixel(true);
        run.font.setLinearMetrics(true);
        run.originX = info->origin.fX;
        run.advanceX = info->advanceX;
        run.glyphs.assign(info->glyphs, info->glyphs + info->count);
        run.positions.assign(info->positions, info->positions + info->count);
        run.starts.assign(info->utf8Starts, info->utf8Starts + info->count + 1);
        runs.push_back(std::move(run));
    });

    // A caret (and a character-split piece) may only stop where a grapheme boundary is also a
    // shaping-cluster boundary: UAX #29 alone splits Sinhala conjuncts and pre-base vowels that
    // HarfBuzz draws as one glyph group.
    QList<bool> insideCluster(source.size() + 1, false);
    for (int p = 0; p < source.size();) {
        int next = p + (source.at(p).isHighSurrogate() && p + 1 < source.size() ? 2 : 1);
        skt::Paragraph::GlyphClusterInfo cluster;
        if (paragraph->getGlyphClusterAt(size_t(utf8.u8At.at(p)), &cluster)
            && cluster.fClusterTextRange.end < size_t(utf8.u16At.size())) {
            const int clusterEnd = utf8.u16At.at(int(cluster.fClusterTextRange.end));
            if (clusterEnd > next) {
                for (int q = next; q < clusterEnd; ++q)
                    insideCluster[q] = true;
                next = clusterEnd;
            }
        }
        p = next;
    }
    const auto validStop = [&](int pos) { return !insideCluster.at(pos); };

    auto layoutData = std::make_shared<ParagraphLayout>();
    layoutData->paragraph = paragraph;
    for (const int stop : graphemes) {
        if (validStop(stop))
            layoutData->caretStops.append(stop);
    }

    // Primary metrics decide the line step and baseline, as the font's own line spacing did; a
    // scaled accent makes the line's own box (from the paragraph) the authority instead.
    sk_sp<SkTypeface> primary;
    {
        const std::vector<sk_sp<SkTypeface>> found = collection->findTypefaces(
            {SkString(resolved.family.toUtf8().constData())},
            SkFontStyle(resolved.weight, SkFontStyle::kNormal_Width,
                        resolved.italic ? SkFontStyle::kItalic_Slant : SkFontStyle::kUpright_Slant));
        if (!found.empty())
            primary = found.front();
    }
    if (!primary)
        primary = drift::skia::systemFontMgr()->legacyMakeTypeface(nullptr, SkFontStyle());
    struct Metrics { double ascent = 0, descent = 0, leading = 0; };
    const auto metricsFor = [&](double px) {
        SkFont font(primary, float(px));
        font.setHinting(SkFontHinting::kNone);
        font.setSubpixel(true);
        font.setLinearMetrics(true);
        SkFontMetrics m;
        font.getMetrics(&m);
        return Metrics{-double(m.fAscent), double(m.fDescent), double(m.fLeading)};
    };
    const Metrics baseMetrics = metricsFor(basePx);
    const Metrics accentMetrics = metricsFor(accentPx);

    QList<double> steps;
    steps.reserve(lineCount);
    double totalH = 0.0;
    for (int i = 0; i < lineCount; ++i) {
        const double natural = mixedSizes ? lines[i].fAscent + lines[i].fDescent
                                          : baseMetrics.ascent + baseMetrics.descent + baseMetrics.leading;
        const double step = natural * qMax(0.1, style.lineHeight);
        steps.append(step);
        totalH += step;
    }

    double blockTop = 0.0;
    if (style.valign == drift::TextVAlign::Middle)
        blockTop = (blockHeight - totalH) * 0.5;
    else if (style.valign == drift::TextVAlign::Bottom)
        blockTop = blockHeight - totalH;
    layoutData->blockTop = blockTop;

    QList<StyledWord> words;
    double y = 0.0;
    for (int i = 0; i < lineCount; ++i) {
        const skt::LineMetrics &lm = lines[i];
        const double lineTop = y;
        y += steps.at(i);

        double lineX = 0.0;
        if (style.align == drift::TextAlign::Center)
            lineX = (wrapWidth - lm.fWidth) * 0.5;
        else if (style.align == drift::TextAlign::Right)
            lineX = wrapWidth - lm.fWidth;

        const double baseline = blockTop + lineTop + (mixedSizes ? lm.fAscent : baseMetrics.ascent);
        layoutData->lineX.append(lineX);
        layoutData->lineBaseline.append(baseline);

        // LineMetrics indexes are UTF-16, unlike the visitor's and the cluster queries'.
        const int start = int(lm.fStartIndex);
        const int end = qMin(int(lm.fEndIncludingNewline), int(source.size()));
        if (end <= start)
            continue;

        for (int wi = 0; wi < ranges.size(); ++wi) {
            // A word wider than the box is broken across lines; each fragment is clamped to the
            // line and keeps the whole word's index and accent.
            const int ws = qMax(ranges.at(wi).start, start);
            const int we = qMin(ranges.at(wi).start + ranges.at(wi).length, end);
            if (we <= ws)
                continue;

            const Metrics &wordMetrics = accentFlags.at(wi) ? accentMetrics : baseMetrics;

            auto appendRun = [&](int from, int to) {
                QString slice = source.mid(from, to - from);
                if (slice.trimmed().isEmpty())
                    return;

                // The glyphs come from the line's own shaping, not a re-shaped slice: a piece
                // cut from a word keeps its joined forms and marks, and RTL runs keep their
                // visual order. A glyph belongs to the piece holding the start of its cluster,
                // so a ligature spanning several pieces stays with the first.
                const uint32_t from8 = uint32_t(utf8.u8At.at(from));
                const uint32_t to8 = uint32_t(utf8.u8At.at(to));
                SkPathBuilder builder;
                bool anyGlyph = false;
                bool anyOutline = false;
                bool anyBounds = false;
                auto geometry = std::make_shared<PieceGeometry>();
                float gx0 = std::numeric_limits<float>::max();
                float gx1 = std::numeric_limits<float>::lowest();
                for (const RunData &run : runs) {
                    if (run.line != i)
                        continue;
                    for (size_t g = 0; g < run.glyphs.size(); ++g) {
                        if (run.starts[g] < from8 || run.starts[g] >= to8)
                            continue;
                        anyGlyph = true;
                        const float gx = float(lineX) + run.originX + run.positions[g].fX;
                        const float gy = float(baseline) + run.positions[g].fY;
                        gx0 = std::min(gx0, gx);
                        gx1 = std::max(gx1, gx + (g + 1 < run.glyphs.size() ? run.positions[g + 1].fX - run.positions[g].fX
                                                                           : run.advanceX - run.positions[g].fX));
                        // Winding, not odd-even: at heavy weights adjacent glyph contours overlap,
                        // and odd-even punches those overlaps out as holes.
                        const std::optional<SkPath> outline = run.font.getPath(run.glyphs[g]);
                        if (outline && !outline->isEmpty()) {
                            anyOutline = true;
                            builder.addPath(*outline, gx, gy);
                        } else if (!run.font.getBounds(run.glyphs[g], nullptr).isEmpty()) {
                            anyBounds = true;
                        }
                        if (geometry->glyphs.empty())
                            geometry->font = run.font;
                        if (run.font.getTypeface() == geometry->font.getTypeface()) {
                            geometry->glyphs.push_back(run.glyphs[g]);
                            geometry->positions.push_back({gx, gy});
                        }
                    }
                }
                if (!anyGlyph)
                    return;

                double x0 = gx0;
                double x1 = gx1;
                const std::vector<skt::TextBox> boxes =
                    paragraph->getRectsForRange(unsigned(from), unsigned(to), skt::RectHeightStyle::kTight,
                                                skt::RectWidthStyle::kTight);
                if (!boxes.empty()) {
                    x0 = std::numeric_limits<double>::max();
                    x1 = std::numeric_limits<double>::lowest();
                    for (const skt::TextBox &box : boxes) {
                        x0 = std::min(x0, lineX + box.rect.left());
                        x1 = std::max(x1, lineX + box.rect.right());
                    }
                }

                StyledWord word;
                word.cellRect = QRectF(x0, baseline - wordMetrics.ascent, x1 - x0,
                                       wordMetrics.ascent + wordMetrics.descent);
                if (!anyOutline && anyBounds) {
                    geometry->colour = true;
                    word.colour = true;
                    word.inkRect = word.cellRect;
                } else {
                    geometry->glyphs.clear();
                    geometry->positions.clear();
                    geometry->path = builder.detach();
                    const QRectF ink = toQRect(geometry->path.getBounds());
                    if (ink.isEmpty())
                        return;
                    word.inkRect = ink;
                }
                word.geometry = std::move(geometry);
                word.baselineY = baseline;
                word.index = wi;
                word.line = i;
                word.accent = accentFlags.at(wi);
                word.charIndex = graphemeAt.at(from);
                word.nonSpaceIndex = words.size();
                word.textStart = from;
                word.textLength = to - from;
                words.append(word);
            };

            // Break the piece into runs of ordinary text and single emoji clusters, so each
            // emoji is its own piece and drawable bitmap; with no emoji in the piece this is the
            // one whole-piece run.
            auto emitPiece = [&](int from, int to) {
                const QList<int> stops = graphemeBoundaries(source, from, to);
                int runStart = -1;
                for (int s = 0; s + 1 < stops.size(); ++s) {
                    const int cs = stops.at(s);
                    const int ce = stops.at(s + 1);
                    if (emojiAt.at(cs)) {
                        if (runStart >= 0)
                            appendRun(runStart, cs);
                        runStart = -1;
                        appendRun(cs, ce);
                    } else if (runStart < 0) {
                        runStart = cs;
                    }
                }
                if (runStart >= 0)
                    appendRun(runStart, to);
            };

            if (split == WordSplit::Characters) {
                // Cluster by cluster, not QChar by QChar: a flag, a ZWJ sequence or a Sinhala
                // conjunct is one character to the reader and must animate as one.
                const QList<int> stops = graphemeBoundaries(source, ws, we);
                int from = ws;
                for (int s = 1; s < stops.size(); ++s) {
                    if (s + 1 < stops.size() && !validStop(stops.at(s)))
                        continue;
                    emitPiece(from, stops.at(s));
                    from = stops.at(s);
                }
            } else {
                emitPiece(ws, we);
            }
        }
    }
    return {words, layoutData};
}

int unresolvedGlyphs(const ParagraphLayout &layout)
{
    std::lock_guard<std::recursive_mutex> lock(drift::skia::textLayoutMutex());
    return drift::skia::paragraphOf(layout) ? drift::skia::paragraphOf(layout)->unresolvedGlyphs() : 0;
}

QString firstFontFamily(const ParagraphLayout &layout)
{
    std::lock_guard<std::recursive_mutex> lock(drift::skia::textLayoutMutex());
    skt::Paragraph *paragraph = drift::skia::paragraphOf(layout);
    if (!paragraph)
        return {};
    SkString family;
    paragraph->getFontAt(0).getTypeface()->getFamilyName(&family);
    return QString::fromUtf8(family.c_str());
}

#else

int unresolvedGlyphs(const ParagraphLayout &)
{
    return 0;
}

QString firstFontFamily(const ParagraphLayout &)
{
    return {};
}

TextLayoutResult layoutStyledText(const QString &, const drift::TextStyle &, double, double, double, int,
                                  WordSplit)
{
    return {};
}

#endif // DRIFT_WITH_SKIA


double textBendRise(const drift::TextStyle &style)
{
    return std::abs(qBound(-100.0, style.pathBend, 100.0)) / 100.0 * 2.0 * style.pixelSize;
}

double highlightBleed(const drift::TextHighlight &highlight)
{
    return highlight.enabled ? highlight.padding + highlight.radius : 0.0;
}

double bleedFor(const drift::TextStyle &style)
{
    const drift::WordAccent &accent = style.accent;
    const bool accented = accent.rule != drift::WordAccentRule::None;

    // Layers do not compound: the widest one sets the margin, plus the stroke every one of them
    // may be drawn over.
    const double stroke = qMax(drift::textStrokeWidth(style, false),
                               accented ? drift::textStrokeWidth(style, true) : 0.0);
    double widest = 0.0;
    for (const drift::TextShadingLayer &layer : style.layers) {
        if (!layer.enabled)
            continue;
        double reach = qMax(std::abs(layer.offsetX), std::abs(layer.offsetY)) + layer.blur * 2.0 + qMax(0.0, layer.spread)
                       + layer.sketchDeviation;
        if (layer.kind == drift::TextLayerKind::Stroke)
            reach += layer.strokeAlign == drift::StrokeAlign::Inside    ? 0.0
                     : layer.strokeAlign == drift::StrokeAlign::Center ? layer.width * 0.5
                                                                        : layer.width;
        else if (layer.kind == drift::TextLayerKind::Extrude)
            reach += layer.width;
        else
            reach += stroke;
        widest = qMax(widest, reach);
    }
    double bleed = qMax(widest, stroke);
    if (style.boxEnabled)
        bleed += style.boxPadding + style.boxRadius;
    bleed += qMax(highlightBleed(style.wordHighlight),
                  accented ? highlightBleed(accent.highlight) : 0.0);
    if (style.underlineEnabled)
        bleed += style.underlineOffset + style.underlineWidth;
    // A scaled accent word overshoots the block's line box on both sides.
    if (accented && accent.sizeScale > 1.0)
        bleed += style.pixelSize * (accent.sizeScale - 1.0);
    // A bent baseline lifts (or drops) the middle of the line by the arc's rise.
    bleed += textBendRise(style);
    return bleed;
}

const drift::TextHighlight *highlightFor(const drift::TextStyle &style, bool accent)
{
    if (accent && style.accent.highlight.enabled)
        return &style.accent.highlight;
    return style.wordHighlight.enabled ? &style.wordHighlight : nullptr;
}

// Fill every word's outline shape into a scratch image and blur it once. One pass serves the whole


// Everything the block actually paints over: outlined glyphs plus any highlight pills. The box
// background sizes to this.
QRectF paintedBounds(const QList<StyledWord> &words, const drift::TextStyle &style, double renderScale)
{
    QRectF bounds;
    for (const StyledWord &word : words) {
        // A colour glyph has no path, so its cell is what the box background and the per-span ink test
        // have to size to — otherwise an emoji-only span is treated as empty and dropped.
        const double grow = drift::textStrokeWidth(style, word.accent) * renderScale;
        QRectF piece = word.colour ? word.cellRect : word.inkRect.adjusted(-grow, -grow, grow, grow);
        if (const drift::TextHighlight *highlight = highlightFor(style, word.accent)) {
            const double pad = highlight->padding * renderScale;
            piece = piece.united(word.cellRect.adjusted(-pad, -pad, pad, pad));
        }
        bounds = bounds.isNull() ? piece : bounds.united(piece);
    }
    return bounds;
}

// ---------------------------------------------------------------------------------------------
// Fragment sets

namespace {

QMutex g_layoutMutex;
QCache<quint64, std::shared_ptr<const FragmentSet>> g_layoutCache(64);

} // namespace

std::shared_ptr<const FragmentSet> fragmentsFor(const QString &text, const drift::TextStyle &style, double wrapWidth,
                                                double blockHeight, double renderScale, int activeWordIndex,
                                                WordSplit split)
{
    const quint64 key = layoutKey(text, style, wrapWidth, blockHeight, renderScale, activeWordIndex, split);
    {
        QMutexLocker lock(&g_layoutMutex);
        if (const auto *hit = g_layoutCache.object(key))
            return *hit;
    }
    auto set = std::make_shared<FragmentSet>();
    set->key = key;
    set->split = split;
    TextLayoutResult laid = layoutStyledText(text, style, renderScale, wrapWidth, blockHeight, activeWordIndex, split);
    set->frags = std::move(laid.words);
    set->paragraph = std::move(laid.paragraph);
    set->infos.reserve(set->frags.size());
    int lines = 0;
    int words = 0;
    for (const StyledWord &w : set->frags) {
        drift::textanim::FragmentInfo info;
        info.charIndex = w.charIndex;
        info.nonSpaceIndex = w.nonSpaceIndex;
        info.wordIndex = w.index;
        info.lineIndex = w.line;
        info.advance = w.cellRect.width();
        info.ascent = w.baselineY - w.cellRect.top();
        info.textStart = w.textStart;
        info.textLength = w.textLength;
        set->infos.append(info);
        lines = qMax(lines, w.line + 1);
        words = qMax(words, w.index + 1);
    }
    QString source = text;
    source.replace(QLatin1Char('\n'), QChar::LineSeparator);
    set->domains.chars = qMax(1, graphemeBoundaries(source, 0, source.size()).size() - 1);
    set->domains.nonSpaceChars = set->frags.size();
    set->domains.words = words;
    set->domains.lines = lines;
    set->ink = paintedBounds(set->frags, style, renderScale);
    QMutexLocker lock(&g_layoutMutex);
    g_layoutCache.insert(key, new std::shared_ptr<const FragmentSet>(set));
    return set;
}

void clearLayoutCache()
{
    QMutexLocker lock(&g_layoutMutex);
    g_layoutCache.clear();
}

WordSplit splitFor(const drift::textanim::ResolvedSlots &resolved, const drift::TextStyle &style)
{
    if (textBendRise(style) > 0.0)
        return WordSplit::Characters;
    const auto perCharacter = [](const QList<drift::TextAnimator> &animators) {
        for (const drift::TextAnimator &a : animators) {
            if (!a.enabled)
                continue;
            for (const drift::TextRangeSelector &s : a.selectors) {
                if (s.domain == drift::TextSelectorDomain::Chars
                    || s.domain == drift::TextSelectorDomain::CharsExcludingSpaces)
                    return true;
            }
        }
        return false;
    };
    return perCharacter(resolved.in) || perCharacter(resolved.out) || perCharacter(resolved.loop)
               ? WordSplit::Characters
               : WordSplit::Whole;
}

drift::textanim::EvalContext evalContextFor(const drift::TextStyle &style, const QRectF &layoutRect,
                                            double renderScale, drift::TimeUs windowStartUs,
                                            drift::TimeUs windowDurationUs, drift::TimeUs timelineUs,
                                            int activeWordIndex)
{
    drift::textanim::EvalContext ctx;
    ctx.windowStartUs = windowStartUs;
    ctx.windowDurationUs = windowDurationUs;
    ctx.timelineUs = timelineUs;
    ctx.emPx = style.pixelSize * renderScale;
    ctx.boxWidthPx = layoutRect.width();
    ctx.boxHeightPx = layoutRect.height();
    ctx.renderScale = renderScale;
    ctx.alignFactor = style.align == drift::TextAlign::Left ? 0.0 : (style.align == drift::TextAlign::Right ? 1.0 : 0.5);
    ctx.activeWordIndex = activeWordIndex;
    ctx.baseFillColor = drift::textFillColor(style, false);
    ctx.baseStrokeColor = drift::textStrokeColor(style, false);
    return ctx;
}

} // namespace drift::text
