#pragma once

#include "include/core/SkRefCnt.h"
#include "include/core/SkTypeface.h"
#include "engine/TextLayout.h"
#include "modules/skparagraph/include/FontCollection.h"
#include "modules/skparagraph/include/Paragraph.h"

#include <QString>
#include <QStringList>

#include <mutex>

// The font bridge between QFontDatabase and SkParagraph. Every font file the app registers with
// Qt (the bundled catalog, addon fonts, the emoji face) is also registered here under the name
// the layout asks for, on top of the platform manager that supplies system families and glyph
// fallback.

namespace drift::skia {

enum class FontGroup { Catalog, Emoji, User };

// Load `path` and make it resolvable as the family `alias`. Thread-safe.
void registerFontFile(FontGroup group, const QString &path, const QString &alias);
// Register every face in `path` (all of a .ttc) under its own family name. Returns the family
// names, empty when Skia cannot read the file. Thread-safe.
QStringList registerFontFaces(FontGroup group, const QString &path);
// Drop the faces one file registered, wherever they were registered from.
void unregisterFontFile(FontGroup group, const QString &path);
// Drop everything a group registered (the catalog is rebuilt from scratch on reload).
void clearRegisteredFonts(FontGroup group);
// The typeface registered under `alias`, or null.
sk_sp<SkTypeface> registeredTypeface(const QString &alias);

// The shared collection. FontCollection and the paragraphs built on it are not thread-safe:
// hold textLayoutMutex() around building, laying out, visiting and querying any paragraph.
// Recursive, so registeredTypeface() may be called with it held.
std::recursive_mutex &textLayoutMutex();
sk_sp<::skia::textlayout::FontCollection> textFontCollection();

// The shaped paragraph behind a layout (null when there is none). Call with textLayoutMutex() held.
inline ::skia::textlayout::Paragraph *paragraphOf(const text::ParagraphLayout &layout)
{
    return static_cast<::skia::textlayout::Paragraph *>(layout.paragraph.get());
}

} // namespace drift::skia
