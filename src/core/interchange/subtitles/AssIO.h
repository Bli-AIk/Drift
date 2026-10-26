#pragma once

#include "core/project/SubtitleCue.h"

#include <QList>
#include <QString>

namespace drift {

// Style/resolution block for an ASS export. Defaults mirror the 720p Aegisub
// baseline this fork targets: Noto Serif CJK SC 64 with a 47px bottom margin.
// Font size, outline, shadow and the vertical margin scale with playResY, so a
// 1080p project keeps the same look as the 720p reference.
struct AssExportStyle
{
    QString fontName = QStringLiteral("Noto Serif CJK SC");
    QString styleName = QStringLiteral("Default");
    QString title;
    int playResX = 1280;
    int playResY = 720;
};

// Serialize cues to Advanced SubStation Alpha (ASS v4.00+) text: one Default
// style, one Dialogue line per cue, h:mm:ss.cc timestamps. Cue times may be
// clip-local or already shifted onto the timeline; this function does not shift
// them.
QString writeAss(const QList<SubtitleCue> &cues, const AssExportStyle &style);

bool writeAssFile(const QString &path, const QList<SubtitleCue> &cues,
                  const AssExportStyle &style, QString *error = nullptr);

} // namespace drift
