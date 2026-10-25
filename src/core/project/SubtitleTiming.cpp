#include "core/project/SubtitleTiming.h"

#include <algorithm>
#include <cmath>

namespace drift {

namespace {

constexpr TimeUs kMinDurationUs = kUsPerMs;

TimeUs roundUs(double value)
{
    return static_cast<TimeUs>(std::llround(value));
}

// Counts before sorting, so indices into the snapshot still match the cues being compared.
int finishEdit(const QList<SubtitleCue> &before, QList<SubtitleCue> &cues)
{
    int changed = 0;
    for (int i = 0; i < cues.size(); ++i) {
        if (cues.at(i).startUs != before.at(i).startUs || cues.at(i).endUs != before.at(i).endUs)
            ++changed;
    }
    sortSubtitleCues(cues);
    return changed;
}

QList<bool> maskOf(int size, const QList<int> &idx)
{
    QList<bool> mask(size, false);
    for (int i : idx)
        mask[i] = true;
    return mask;
}

template <typename Map>
int remapCues(QList<SubtitleCue> &cues, const QList<int> &idx, Map map)
{
    const QList<SubtitleCue> before = cues;
    for (int i : idx) {
        SubtitleCue &cue = cues[i];
        cue.startUs = std::max<TimeUs>(0, map(cue.startUs));
        cue.endUs = std::max(map(cue.endUs), cue.startUs + kMinDurationUs);
    }
    return finishEdit(before, cues);
}

} // namespace

int shiftCues(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs deltaUs, SubtitleEdges edges)
{
    const QList<SubtitleCue> before = cues;
    for (int i : idx) {
        SubtitleCue &cue = cues[i];
        switch (edges) {
        case SubtitleEdges::Both:
            if (cue.startUs + deltaUs < 0) {
                const TimeUs duration = cue.endUs - cue.startUs;
                cue.startUs = 0;
                cue.endUs = duration;
            } else {
                cue.startUs += deltaUs;
                cue.endUs += deltaUs;
            }
            break;
        case SubtitleEdges::Start:
            cue.startUs = std::max<TimeUs>(
                0, std::min(cue.startUs + deltaUs, cue.endUs - kMinDurationUs));
            break;
        case SubtitleEdges::End:
            cue.endUs = std::max(cue.endUs + deltaUs, cue.startUs + kMinDurationUs);
            break;
        }
    }
    return finishEdit(before, cues);
}

int linearResync(QList<SubtitleCue> &cues, const QList<int> &idx, SubtitleSyncPoint a,
                 SubtitleSyncPoint b)
{
    // With equal source points there is no slope to solve for, so fall back to a plain offset.
    const bool pureOffset = a.fromUs == b.fromUs;
    const double slope =
        pureOffset ? 1.0
                   : static_cast<double>(b.toUs - a.toUs) / static_cast<double>(b.fromUs - a.fromUs);
    return remapCues(cues, idx, [&](TimeUs t) {
        return roundUs(static_cast<double>(a.toUs) +
                       static_cast<double>(t - a.fromUs) * slope);
    });
}

int scaleCues(QList<SubtitleCue> &cues, const QList<int> &idx, double factor, TimeUs originUs)
{
    if (!(factor > 0.0))
        return 0;
    return remapCues(cues, idx, [&](TimeUs t) {
        return roundUs(static_cast<double>(originUs) +
                       static_cast<double>(t - originUs) * factor);
    });
}

int bridgeGaps(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs maxGapUs, TimeUs minGapUs,
               double prevRatio)
{
    const QList<SubtitleCue> before = cues;
    const QList<bool> inIdx = maskOf(cues.size(), idx);
    const double ratio = std::clamp(prevRatio, 0.0, 1.0);
    minGapUs = std::max<TimeUs>(0, minGapUs);
    for (int i = 0; i + 1 < cues.size(); ++i) {
        if (!inIdx.at(i))
            continue;
        const TimeUs gap = cues.at(i + 1).startUs - cues.at(i).endUs;
        if (gap <= minGapUs || gap >= maxGapUs)
            continue;

        const TimeUs removed = gap - minGapUs;
        const bool nextEditable = inIdx.at(i + 1);
        const TimeUs toPrev =
            nextEditable ? std::clamp<TimeUs>(roundUs(static_cast<double>(removed) * ratio), 0,
                                              removed)
                         : removed;
        cues[i].endUs += toPrev;
        if (nextEditable)
            cues[i + 1].startUs -= removed - toPrev;
    }
    return finishEdit(before, cues);
}

int enforceMinGap(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs minGapUs)
{
    const QList<SubtitleCue> before = cues;
    const QList<bool> inIdx = maskOf(cues.size(), idx);
    for (int i = 0; i + 1 < cues.size(); ++i) {
        if (!inIdx.at(i))
            continue;
        const TimeUs nextStart = cues.at(i + 1).startUs;
        if (nextStart - cues.at(i).endUs >= minGapUs)
            continue;
        cues[i].endUs =
            std::max(nextStart - minGapUs, cues.at(i).startUs + kMinDurationUs);
    }
    return finishEdit(before, cues);
}

int addLeadInOut(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs leadInUs,
                 TimeUs leadOutUs)
{
    const QList<SubtitleCue> before = cues;
    // All lead-ins run before any lead-out, so a shared gap goes to the next cue's lead-in.
    // Lead-ins are bounded by the previous cue's original end, which keeps them from creating
    // overlaps while lead-outs are still unapplied.
    for (int i : idx) {
        const TimeUs prevEnd = i > 0 ? cues.at(i - 1).endUs : 0;
        SubtitleCue &cue = cues[i];
        const TimeUs wanted = std::max<TimeUs>(0, cue.startUs - leadInUs);
        cue.startUs = std::min(cue.startUs, std::max(wanted, prevEnd));
    }
    for (int i : idx) {
        SubtitleCue &cue = cues[i];
        TimeUs wanted = cue.endUs + leadOutUs;
        if (i + 1 < cues.size())
            wanted = std::min(wanted, cues.at(i + 1).startUs);
        cue.endUs = std::max(cue.endUs, wanted);
    }
    return finishEdit(before, cues);
}

int clampDurations(QList<SubtitleCue> &cues, const QList<int> &idx, TimeUs minUs, TimeUs maxUs)
{
    const QList<SubtitleCue> before = cues;
    for (int i : idx) {
        SubtitleCue &cue = cues[i];
        if (maxUs > 0 && cue.endUs - cue.startUs > maxUs)
            cue.endUs = cue.startUs + maxUs;
        if (cue.endUs - cue.startUs < minUs) {
            TimeUs target = cue.startUs + minUs;
            if (i + 1 < cues.size())
                target = std::min(target, cues.at(i + 1).startUs);
            cue.endUs = std::max(cue.endUs, target);
        }
    }
    return finishEdit(before, cues);
}

int fixOverlaps(QList<SubtitleCue> &cues, const QList<int> &idx)
{
    const QList<SubtitleCue> before = cues;
    const QList<bool> inIdx = maskOf(cues.size(), idx);
    for (int i = 0; i + 1 < cues.size(); ++i) {
        if (!inIdx.at(i) || cues.at(i).endUs <= cues.at(i + 1).startUs)
            continue;
        cues[i].endUs =
            std::max(cues.at(i + 1).startUs, cues.at(i).startUs + kMinDurationUs);
    }
    return finishEdit(before, cues);
}

QList<int> subtitleScopeIndices(const QList<SubtitleCue> &cues, int scope,
                                const QList<int> &selected, TimeUs fromUs)
{
    QList<int> out;
    switch (scope) {
    case 0:
        for (int i = 0; i < cues.size(); ++i)
            out.append(i);
        break;
    case 1:
        for (int i : selected) {
            if (i >= 0 && i < cues.size())
                out.append(i);
        }
        std::sort(out.begin(), out.end());
        out.erase(std::unique(out.begin(), out.end()), out.end());
        break;
    case 2:
        for (int i = 0; i < cues.size(); ++i) {
            if (cues.at(i).startUs >= fromUs)
                out.append(i);
        }
        break;
    default:
        break;
    }
    return out;
}

} // namespace drift
