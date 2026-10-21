#pragma once

#include <QByteArray>
#include <QString>

namespace drift {

// Gradient and curve params baked to a 256x1 RGBA8 texture, texel i at t = i / 255. Empty when the
// JSON is malformed or has no stops/keys.
QByteArray bakeGradient(const QString &json);
QByteArray bakeCurve(const QString &json);

} // namespace drift
