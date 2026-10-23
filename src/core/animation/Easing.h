#pragma once

#include <QJsonObject>
#include <QList>
#include <QPointF>
#include <QString>
#include <QVector>

#include <optional>

namespace drift {

// Robert Penner curves. They shape a whole keyframe segment in normalized time, the way a
// bezier does, but cannot be written as a cubic, so they are stored as a function id instead.
enum class EasingFn { None, ElasticIn, ElasticOut, ElasticInOut, BounceIn, BounceOut, BounceInOut };

QString easingFnToString(EasingFn fn);
EasingFn easingFnFromString(const QString &id);

// u is clamped to [0, 1]; the endpoints are exact so a segment always lands on its keys.
double evaluateEasingFn(EasingFn fn, double u, double amplitude, double period);

// What a keyframe segment's easing is, independent of how it is stored on the keys.
struct EasingSpec
{
    enum class Kind { Linear, Hold, Bezier, Function };

    Kind kind = Kind::Linear;
    double x1 = 0.0;
    double y1 = 0.0;
    double x2 = 1.0;
    double y2 = 1.0;
    EasingFn fn = EasingFn::None;
    double amplitude = 1.0;
    double period = 0.3;

    QJsonObject toJson() const;
    static EasingSpec fromJson(const QJsonObject &object);

    QString toCssString() const;
    static std::optional<EasingSpec> parseCss(const QString &css);

    bool approxEquals(const EasingSpec &other, double tol = 1e-3) const;
};

struct EasingPreset
{
    QString id;
    QString label;
    QString family;
    EasingSpec spec;
};

const QList<EasingPreset> &builtinEasingPresets();
const EasingPreset *findBuiltinEasingPreset(const QString &id);
QString matchBuiltinEasingPreset(const EasingSpec &spec);

// n + 1 points from x = 0 to x = 1.
QVector<QPointF> sampleEasing(const EasingSpec &spec, int n);

} // namespace drift
