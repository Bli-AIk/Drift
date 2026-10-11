#pragma once

#include "include/core/SkFont.h"
#include "include/core/SkPath.h"
#include "include/core/SkPoint.h"

#include <vector>

// What TextLayout keeps per piece in Skia's own types, so TextLayout.h stays Skia-free. Read by
// the layout (which fills it) and SkiaTextPainter (which draws it).

namespace drift::text {

struct PieceGeometry
{
    SkPath path; // glyph outlines, winding fill, block-local; empty for a colour piece

    // A colour glyph run (bitmap or layered emoji) has no outline to fill; it is drawn as a
    // blob from these instead, positions block-local.
    bool colour = false;
    SkFont font;
    std::vector<SkGlyphID> glyphs;
    std::vector<SkPoint> positions;
};

} // namespace drift::text
