#pragma once

#include "TextLayout.h"
#include "VectorPainter.h"
#include "core/Clip.h"
#include "core/TextAnimator.h"

#include <QColor>
#include <QList>
#include <QRectF>
#include <QString>

#include <memory>

// The Skia text painter. Layout is TextLayout's (SkParagraph pieces, bleed and cache keys); the
// animator engine's frame says where every fragment sits at this instant; the shading stack says
// how each is painted. Skia-free header.

namespace drift::skia {

struct TextPainterResult
{
    std::shared_ptr<const VectorPainter> painter; // null when there is nothing to draw
    QRectF rect;                                  // destination in canvas px, bleed included
    // Whole-block motion the painter leaves to its host: the compositor puts it on the GPU
    // layer, a CPU card has to apply it itself.
    textanim::BlockProps block;
};

struct TextPaintRequest
{
    std::shared_ptr<const text::FragmentSet> set;
    textanim::Frame frame;
    TextStyle style; // already resolvedAt() the instant
    QRectF layoutRect;
    double renderScale = 1.0;
    double timeSec = 0.0; // since the window start; drives time-based paints
    textanim::Bounds envelope;
    TextAnchorGrouping anchorGrouping = TextAnchorGrouping::Character;
    QPointF anchorAlignment;
};

TextPainterResult makeTextPainter(const TextPaintRequest &request);

// The inline editor's decorations for a text block, drawn apart from the glyphs so the clip's
// effects never touch them: the selection, the preedit underline and the caret. Offsets are
// UTF-16 into the text `set` was laid out from; -1 / empty ranges draw nothing.
struct TextEditPaintRequest
{
    std::shared_ptr<const text::FragmentSet> set;
    QRectF layoutRect;
    double renderScale = 1.0;
    int cursor = -1;
    int selStart = -1;
    int selEnd = -1;
    int preeditStart = -1;
    int preeditLength = 0;
    QColor caretColor;     // invalid = white
    QColor selectionColor; // invalid = translucent blue
};

// The painter's rect is the layout rect grown evenly on every side, so a layer that rotates about
// its centre turns it the same way the text's own layer turns.
TextPainterResult makeTextEditPainter(const TextEditPaintRequest &request);

// Lays the text out and evaluates its animation at clipTimeUs inside the clip's own window (3 s
// when the clip has no duration); -1 picks the middle of the hold. For thumbnails and tests.
TextPainterResult makeTextPainter(const Clip &clip, const QString &text, const QRectF &layoutRect,
                                  double renderScale, int activeWordIndex = -1, TimeUs clipTimeUs = -1);

void clearTextGeometryCache();

} // namespace drift::skia
