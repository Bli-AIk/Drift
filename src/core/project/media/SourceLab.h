#pragma once

#include "core/base/Time.h"

#include <QJsonObject>
#include <QList>
#include <QString>

#include <algorithm>
#include <cmath>

namespace drift {

// A named span of one source asset, marked in Source Lab. Independent of the asset's single
// non-destructive trim: an asset can hold many ranges.
struct SourceRange
{
    QString id;
    TimeUs inUs = 0;
    TimeUs outUs = 0;
    // -1 reject, 0 none, 1 favorite.
    int rating = 0;
    QString name;
    QString note;
};

struct SourceMarker
{
    QString id;
    TimeUs timeUs = 0;
    QString name;
    QString note;
};

inline QJsonObject toJson(const SourceRange &range)
{
    QJsonObject object{
        {QStringLiteral("id"), range.id},
        {QStringLiteral("inUs"), static_cast<double>(range.inUs)},
        {QStringLiteral("outUs"), static_cast<double>(range.outUs)},
    };
    if (range.rating != 0)
        object.insert(QStringLiteral("rating"), range.rating);
    if (!range.name.isEmpty())
        object.insert(QStringLiteral("name"), range.name);
    if (!range.note.isEmpty())
        object.insert(QStringLiteral("note"), range.note);
    return object;
}

inline SourceRange sourceRangeFromJson(const QJsonObject &object)
{
    SourceRange range;
    range.id = object.value(QStringLiteral("id")).toString();
    range.inUs = static_cast<TimeUs>(object.value(QStringLiteral("inUs")).toDouble());
    range.outUs = static_cast<TimeUs>(object.value(QStringLiteral("outUs")).toDouble());
    range.rating = qBound(-1, object.value(QStringLiteral("rating")).toInt(), 1);
    range.name = object.value(QStringLiteral("name")).toString();
    range.note = object.value(QStringLiteral("note")).toString();
    return range;
}

inline QJsonObject toJson(const SourceMarker &marker)
{
    QJsonObject object{
        {QStringLiteral("id"), marker.id},
        {QStringLiteral("timeUs"), static_cast<double>(marker.timeUs)},
    };
    if (!marker.name.isEmpty())
        object.insert(QStringLiteral("name"), marker.name);
    if (!marker.note.isEmpty())
        object.insert(QStringLiteral("note"), marker.note);
    return object;
}

inline SourceMarker sourceMarkerFromJson(const QJsonObject &object)
{
    SourceMarker marker;
    marker.id = object.value(QStringLiteral("id")).toString();
    marker.timeUs = static_cast<TimeUs>(object.value(QStringLiteral("timeUs")).toDouble());
    marker.name = object.value(QStringLiteral("name")).toString();
    marker.note = object.value(QStringLiteral("note")).toString();
    return marker;
}

// Where source time `t` of a file lands in a render of [trimIn, ...) played at `speed`, clamped
// to the render's length.
inline TimeUs rebaseSourceTime(TimeUs t, TimeUs trimIn, double speed, TimeUs newDuration)
{
    const double rebased = static_cast<double>(t - trimIn) / (speed > 0.0 ? speed : 1.0);
    return std::clamp<TimeUs>(static_cast<TimeUs>(std::llround(rebased)), 0, newDuration);
}

// Ranges carried onto a render; those left empty once clamped (fully outside the kept span) are
// dropped.
inline QList<SourceRange> rebaseRanges(const QList<SourceRange> &ranges, TimeUs trimIn, double speed,
                                       TimeUs newDuration)
{
    QList<SourceRange> out;
    for (SourceRange range : ranges) {
        range.inUs = rebaseSourceTime(range.inUs, trimIn, speed, newDuration);
        range.outUs = rebaseSourceTime(range.outUs, trimIn, speed, newDuration);
        if (range.outUs > range.inUs)
            out.append(range);
    }
    return out;
}

// Markers outside the kept span are dropped rather than pinned to its ends.
inline QList<SourceMarker> rebaseMarkers(const QList<SourceMarker> &markers, TimeUs trimIn,
                                         double speed, TimeUs newDuration)
{
    QList<SourceMarker> out;
    for (SourceMarker marker : markers) {
        const double rebased =
            static_cast<double>(marker.timeUs - trimIn) / (speed > 0.0 ? speed : 1.0);
        if (rebased < 0.0 || rebased > static_cast<double>(newDuration))
            continue;
        marker.timeUs = rebaseSourceTime(marker.timeUs, trimIn, speed, newDuration);
        out.append(marker);
    }
    return out;
}

} // namespace drift
