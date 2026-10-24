#pragma once

#include "core/interchange/subtitles/SubtitleParse.h"
#include "core/project/SubtitleCue.h"

#include <QList>
#include <QString>

namespace drift {

// Parse WebVTT text into clip-local cues. Requires a WEBVTT header; NOTE, STYLE and REGION blocks
// are skipped, cue identifiers are optional, and cue settings after the end timestamp are ignored.
// Timestamps may be mm:ss.ttt or hh:mm:ss.ttt. Any error makes the parse return false.
bool parseVtt(const QString &content, QList<SubtitleCue> *outCues, QString *error = nullptr);
bool parseVttFile(const QString &path, QList<SubtitleCue> *outCues, QString *error = nullptr);

// Serialize cues to WebVTT text (UTF-8, WEBVTT header, no cue identifiers).
QString writeVtt(const QList<SubtitleCue> &cues);
bool writeVttFile(const QString &path, const QList<SubtitleCue> &cues, QString *error = nullptr);

// Lenient: keeps every valid block and records one error per invalid one.
SubtitleParseResult parseVttDetailed(const QString &content);

} // namespace drift
