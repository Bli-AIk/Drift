#pragma once

#include "core/base/Time.h"
#include "core/project/SubtitleCue.h"

#include <QList>

namespace drift {

// Timing edits operate on the cues named in idx (ascending valid indices). Cues outside idx are
// never modified but still act as neighbours and obstacles. Each function returns the number of
// cues whose start or end changed, then leaves cues sorted by start.

enum class SubtitleEdges { Both, Start, End };

int shiftCues(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs deltaUs,
              SubtitleEdges edges = SubtitleEdges::Both);

struct SubtitleSyncPoint
{
    TimeUs fromUs = 0;
    TimeUs toUs = 0;
};

int linearResync(QList<SubtitleCue> &cues, const QList<int> &idx, SubtitleSyncPoint a,
                 SubtitleSyncPoint b);

// factor <= 0 is rejected and changes nothing.
int scaleCues(QList<SubtitleCue> &cues, const QList<int> &idx, double factor, TimeUs originUs = 0);

int bridgeGaps(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs maxGapUs, TimeUs minGapUs,
               double prevRatio);

int enforceMinGap(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs minGapUs);

int addLeadInOut(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs leadInUs,
                 TimeUs leadOutUs);

// maxUs <= 0 disables the maximum.
int clampDurations(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs minUs, TimeUs maxUs);

int fixOverlaps(QList<SubtitleCue> &cues, const QList<int> &idx);

// scope: 0 = all cues, 1 = selected (valid, sorted, unique), 2 = cues starting at or after fromUs.
QList<int> subtitleScopeIndices(const QList<SubtitleCue> &cues, int scope,
                                const QList<int> &selected, TimeUs fromUs);

} // namespace drift
