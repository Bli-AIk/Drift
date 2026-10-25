#pragma once

#include "core/base/Time.h"

#include <QtGlobal>

#include <cmath>

namespace drift {

// Frame arithmetic for the asset player. Frame n starts at round(n / fps), the same rounding the
// demuxer applies when it rescales a pts to microseconds, so a seek to frameTimeUs(n) lands on
// frame n rather than the one before it.
inline double frameGridFps(double fps)
{
    return fps > 0.5 ? fps : 30.0;
}

inline TimeUs frameTimeUs(int frame, double fps)
{
    return static_cast<TimeUs>(std::llround(static_cast<double>(frame) * kUsPerSecond / frameGridFps(fps)));
}

// The frame on screen at `us`. The epsilon keeps a time that is a hair under a boundary through
// rounding from reading as the previous frame.
inline int frameIndexAt(TimeUs us, double fps)
{
    return static_cast<int>(std::floor(static_cast<double>(us) * frameGridFps(fps) / kUsPerSecond + 1e-3));
}

inline TimeUs snapToFrameUs(TimeUs us, double fps)
{
    return frameTimeUs(static_cast<int>(std::llround(static_cast<double>(us) * frameGridFps(fps) / kUsPerSecond)), fps);
}

// The last frame that starts before `durationUs`; 0 for an empty source.
inline int lastFrameIndex(TimeUs durationUs, double fps)
{
    if (durationUs <= 0)
        return 0;
    return qMax(0, static_cast<int>(std::ceil(static_cast<double>(durationUs) * frameGridFps(fps) / kUsPerSecond - 1e-3)) - 1);
}

// JKL shuttle. The legal rates are 0 (stopped), ±1, ±2, ±4 and ±8.
inline bool isShuttleRate(int rate)
{
    const int mag = rate < 0 ? -rate : rate;
    return mag == 0 || mag == 1 || mag == 2 || mag == 4 || mag == 8;
}

// L/J escalation. Pressing the key for the direction already moving doubles the speed up to 8x;
// pressing the opposite key stops first, and only a press from stopped reverses direction.
inline int shuttleNext(int current, bool forward)
{
    const int mag = current < 0 ? -current : current;
    if (current == 0)
        return forward ? 1 : -1;
    if ((current > 0) != forward)
        return 0;
    const int next = mag >= 8 ? 8 : mag * 2;
    return forward ? next : -next;
}

} // namespace drift
