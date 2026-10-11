#pragma once

#include "include/core/SkFontMgr.h"
#include "include/core/SkRefCnt.h"

#include <QStringList>

// Skia font managers. Lottie text layers and SVG <text> resolve families through one of these;
// the text renderer (R4) adds the addon-font manager and typeface lookup here.

namespace drift::skia {

// The platform's font manager: fontconfig on Linux, the system font list on Android, CoreText on
// macOS, the standard font folders where only the FreeType directory port is compiled in, an
// empty manager where nothing is. Created once, shared, thread-safe.
sk_sp<SkFontMgr> systemFontMgr();

// Sorted, de-duplicated family names the system manager enumerates. Computed once.
QStringList systemFontFamilies();

} // namespace drift::skia
