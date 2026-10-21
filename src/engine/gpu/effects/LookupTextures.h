#pragma once

#include <QByteArray>
#include <QPointF>
#include <QString>

#include <vector>

namespace drift {

// Gradient and curve params baked to a 256x1 RGBA8 texture, texel i at t = i / 255. Empty when the
// JSON is malformed or has no stops/keys.
QByteArray bakeGradient(const QString &json);
QByteArray bakeCurve(const QString &json);

// Monotone cubic (Fritsch-Carlson) through keys sorted by x, evaluated at x and clamped to [0,1].
double evalMonotoneSpline(const std::vector<QPointF> &keys, double x);

} // namespace drift
