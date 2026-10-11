#pragma once

#include "core/TextAnimator.h"
#include "core/TextStyle.h"

#include <QColor>
#include <QList>
#include <QRectF>
#include <QString>

#include <memory>

// The layout half of text rendering: word/grapheme splitting, SkParagraph line breaking and
// shaping, placement, accent resolution, bleed and cache keys. The Skia painter (SkiaTextPainter)
// draws exactly these pieces; the animator engine (core/TextAnimator) gets their metadata as
// fragments.

namespace drift::text {

struct PieceGeometry; // Skia types; see SkiaTextGeometry.h

// One drawable piece of the block: a whole word, or a single character of one when the caller
// asked for a character split. Everything is in block-local coordinates (0,0 = layout rect
// top-left) and the piece carries the word's accent state, so painting never re-derives it.
struct StyledWord
{
    std::shared_ptr<const PieceGeometry> geometry;
    QRectF inkRect;
    QRectF cellRect;      // advance width × the font's ascent..descent band: the highlight pill
    double baselineY = 0.0;
    int index = 0;        // reading-order word index; shared by every character of a word
    int line = 0;
    bool accent = false;
    int charIndex = 0;    // grapheme ordinal in the source text, spaces included
    int nonSpaceIndex = 0;// ordinal among the drawn pieces
    int textStart = 0;    // [textStart, textStart + textLength) in the source string
    int textLength = 0;

    // A colour glyph run (emoji): no outline to fill, drawn as glyphs at paint time.
    bool colour = false;
};

enum class WordSplit { Whole, Characters };

struct WordRange { int start; int length; };

// Everything about a style that changes pixels; excludes the animation and the time.
quint64 styleHash(const TextStyle &s);
// Everything that determines the laid-out pieces.
quint64 layoutKey(const QString &text, const TextStyle &s, double wrapWidth, double blockHeight,
                  double renderScale, int activeWordIndex, WordSplit split);

// The grapheme cluster boundaries inside [from, to), ends included.
QList<int> graphemeBoundaries(const QString &source, int from, int to);
QList<WordRange> wordRanges(const QString &source);

// The shaped paragraph behind a layout, kept for the inline editor: hit-testing and range
// rectangles come from it in paragraph coordinates, and the offsets below move those into the
// block-local space the pieces use. The header stays Skia-free, hence the opaque handle: paragraphOf()
// (SkiaFontCollection.h) gets the typed pointer. Paragraph calls are not thread-safe; hold
// drift::skia::textLayoutMutex() (SkiaFontCollection.h) around them.
struct ParagraphLayout
{
    std::shared_ptr<void> paragraph; // a skia::textlayout::Paragraph; see paragraphOf()
    QList<double> lineX;        // per line: x added to the paragraph's x (the manual alignment)
    QList<double> lineBaseline; // per line: block-local baseline y
    double blockTop = 0.0;      // the valign offset applied to the paragraph's own y
    // UTF-16 offsets a caret may stop at, ascending, 0 and text.size() included: grapheme
    // boundaries that are also shaping-cluster boundaries, so a Sinhala conjunct or a
    // consonant plus its pre-base vowel is never split.
    QList<int> caretStops;
};

// Glyphs no font in the collection could draw (the missing-glyph boxes), and the family the
// first run was shaped with.
int unresolvedGlyphs(const ParagraphLayout &layout);
QString firstFontFamily(const ParagraphLayout &layout);

struct TextLayoutResult
{
    QList<StyledWord> words;
    std::shared_ptr<const ParagraphLayout> paragraph;
};

// Lay the text out and split it into per-word (or per-character) pieces.
TextLayoutResult layoutStyledText(const QString &text, const TextStyle &style, double renderScale,
                                  double wrapWidth, double blockHeight, int activeWordIndex,
                                  WordSplit split);

// One layout run, shared by every consumer that needs the same text at the same size: the
// pieces plus the per-fragment metadata the animator engine works from.
struct FragmentSet
{
    QList<StyledWord> frags;
    QList<textanim::FragmentInfo> infos; // index-parallel with frags
    textanim::Domains domains;
    std::shared_ptr<const ParagraphLayout> paragraph;
    QRectF ink;                          // paintedBounds() at rest
    quint64 key = 0;
    WordSplit split = WordSplit::Whole;
};
// Cached (mutex-guarded LRU) so the preview workers, the export thread and the thumbnail
// provider never repeat a paragraph layout for the same request.
std::shared_ptr<const FragmentSet> fragmentsFor(const QString &text, const TextStyle &style, double wrapWidth,
                                                double blockHeight, double renderScale, int activeWordIndex,
                                                WordSplit split);
void clearLayoutCache();

// The split the animators need: characters when any selector works per character (or the line
// is bent, which places glyphs one at a time), else whole words.
WordSplit splitFor(const textanim::ResolvedSlots &resolved, const TextStyle &style);
// The evaluation context for one text window (a clip, or a subtitle cue) at `timelineUs`.
textanim::EvalContext evalContextFor(const TextStyle &style, const QRectF &layoutRect, double renderScale,
                                     TimeUs windowStartUs, TimeUs windowDurationUs, TimeUs timelineUs,
                                     int activeWordIndex);

// Margin (project px) the style can paint outside the layout rect: strokes, shadows, glows,
// extrusions, box, pills, underline, scaled accents and the bend rise. The animation envelope is
// added by the painter.
double bleedFor(const TextStyle &style);
// How far (project px) pathBend lifts the middle of the line: |bend|/100 × 2 em.
double textBendRise(const TextStyle &style);

const TextHighlight *highlightFor(const TextStyle &style, bool accent);

// Everything the block paints over: stroked glyphs plus any highlight pills.
QRectF paintedBounds(const QList<StyledWord> &words, const TextStyle &style, double renderScale);

} // namespace drift::text
