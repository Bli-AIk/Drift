#pragma once

#include "core/project/SubtitleCue.h"

#include <QList>
#include <QString>

namespace drift {

struct SubtitleParseError
{
    int line = 0; // 1-based line in the input text
    QString message;
};

struct SubtitleParseResult
{
    QList<SubtitleCue> cues;
    QList<SubtitleParseError> errors;
};

} // namespace drift
