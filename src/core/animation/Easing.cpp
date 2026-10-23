#include "core/animation/Easing.h"

#include "core/base/Bezier.h"

#include <QCoreApplication>
#include <QJsonValue>
#include <QStringList>
#include <QtMath>

namespace drift {

namespace {

constexpr double kPi = 3.14159265358979323846;

struct FnId
{
    EasingFn fn;
    const char *id;
};

constexpr FnId kFnIds[] = {
    {EasingFn::ElasticIn, "elasticIn"},     {EasingFn::ElasticOut, "elasticOut"},
    {EasingFn::ElasticInOut, "elasticInOut"}, {EasingFn::BounceIn, "bounceIn"},
    {EasingFn::BounceOut, "bounceOut"},     {EasingFn::BounceInOut, "bounceInOut"},
};

double bounceOut(double t)
{
    constexpr double n = 7.5625;
    constexpr double d = 2.75;
    if (t < 1.0 / d)
        return n * t * t;
    if (t < 2.0 / d) {
        t -= 1.5 / d;
        return n * t * t + 0.75;
    }
    if (t < 2.5 / d) {
        t -= 2.25 / d;
        return n * t * t + 0.9375;
    }
    t -= 2.625 / d;
    return n * t * t + 0.984375;
}

// Elastic amplitude below 1 is not a real overshoot; clamp it and use the period as the phase.
void elasticParams(double amplitude, double period, double &a, double &s)
{
    if (amplitude < 1.0) {
        a = 1.0;
        s = period / 4.0;
    } else {
        a = amplitude;
        s = period / (2.0 * kPi) * qAsin(1.0 / a);
    }
}

double elasticIn(double t, double amplitude, double period)
{
    double a = 0.0;
    double s = 0.0;
    elasticParams(amplitude, period, a, s);
    t -= 1.0;
    return -a * qPow(2.0, 10.0 * t) * qSin((t - s) * 2.0 * kPi / period);
}

double elasticOut(double t, double amplitude, double period)
{
    double a = 0.0;
    double s = 0.0;
    elasticParams(amplitude, period, a, s);
    return a * qPow(2.0, -10.0 * t) * qSin((t - s) * 2.0 * kPi / period) + 1.0;
}

double elasticInOut(double t, double amplitude, double period)
{
    double a = 0.0;
    double s = 0.0;
    elasticParams(amplitude, period, a, s);
    t *= 2.0;
    if (t < 1.0) {
        t -= 1.0;
        return -0.5 * a * qPow(2.0, 10.0 * t) * qSin((t - s) * 2.0 * kPi / period);
    }
    t -= 1.0;
    return 0.5 * a * qPow(2.0, -10.0 * t) * qSin((t - s) * 2.0 * kPi / period) + 1.0;
}

EasingSpec bezierSpec(double x1, double y1, double x2, double y2)
{
    EasingSpec spec;
    spec.kind = EasingSpec::Kind::Bezier;
    spec.x1 = x1;
    spec.y1 = y1;
    spec.x2 = x2;
    spec.y2 = y2;
    return spec;
}

EasingSpec functionSpec(EasingFn fn)
{
    EasingSpec spec;
    spec.kind = EasingSpec::Kind::Function;
    spec.fn = fn;
    return spec;
}

// Shortest decimal that still round-trips at the precision a CSS easing needs.
QString formatNumber(double value)
{
    QString text = QString::number(value, 'f', 3);
    if (text.contains(QLatin1Char('.'))) {
        while (text.endsWith(QLatin1Char('0')))
            text.chop(1);
        if (text.endsWith(QLatin1Char('.')))
            text.chop(1);
    }
    return text;
}

std::optional<QList<double>> parseNumbers(const QString &text, int count)
{
    const QStringList parts = text.split(QLatin1Char(','));
    if (parts.size() != count)
        return std::nullopt;
    QList<double> values;
    for (const QString &part : parts) {
        bool ok = false;
        const double value = part.toDouble(&ok);
        if (!ok)
            return std::nullopt;
        values.append(value);
    }
    return values;
}

} // namespace

QString easingFnToString(EasingFn fn)
{
    for (const FnId &entry : kFnIds) {
        if (entry.fn == fn)
            return QString::fromLatin1(entry.id);
    }
    return {};
}

EasingFn easingFnFromString(const QString &id)
{
    for (const FnId &entry : kFnIds) {
        if (id == QLatin1String(entry.id))
            return entry.fn;
    }
    return EasingFn::None;
}

double evaluateEasingFn(EasingFn fn, double u, double amplitude, double period)
{
    const double t = qBound(0.0, u, 1.0);
    if (fn == EasingFn::None)
        return t;
    if (t <= 0.0)
        return 0.0;
    if (t >= 1.0)
        return 1.0;

    switch (fn) {
    case EasingFn::ElasticIn:
        return elasticIn(t, amplitude, period);
    case EasingFn::ElasticOut:
        return elasticOut(t, amplitude, period);
    case EasingFn::ElasticInOut:
        return elasticInOut(t, amplitude, period);
    case EasingFn::BounceIn:
        return 1.0 - bounceOut(1.0 - t);
    case EasingFn::BounceOut:
        return bounceOut(t);
    case EasingFn::BounceInOut:
        return t < 0.5 ? 0.5 * (1.0 - bounceOut(1.0 - 2.0 * t)) : 0.5 * (1.0 + bounceOut(2.0 * t - 1.0));
    case EasingFn::None:
        break;
    }
    return t;
}

QJsonObject EasingSpec::toJson() const
{
    switch (kind) {
    case Kind::Hold:
        return QJsonObject{{QStringLiteral("kind"), QStringLiteral("hold")}};
    case Kind::Bezier:
        return QJsonObject{
            {QStringLiteral("kind"), QStringLiteral("bezier")},
            {QStringLiteral("x1"), x1},
            {QStringLiteral("y1"), y1},
            {QStringLiteral("x2"), x2},
            {QStringLiteral("y2"), y2},
        };
    case Kind::Function:
        return QJsonObject{
            {QStringLiteral("kind"), QStringLiteral("function")},
            {QStringLiteral("fn"), easingFnToString(fn)},
            {QStringLiteral("amplitude"), amplitude},
            {QStringLiteral("period"), period},
        };
    case Kind::Linear:
        break;
    }
    return QJsonObject{{QStringLiteral("kind"), QStringLiteral("linear")}};
}

EasingSpec EasingSpec::fromJson(const QJsonObject &object)
{
    EasingSpec spec;
    const QString kind = object.value(QStringLiteral("kind")).toString();
    if (kind == QLatin1String("hold")) {
        spec.kind = Kind::Hold;
    } else if (kind == QLatin1String("bezier")) {
        spec.kind = Kind::Bezier;
        spec.x1 = object.value(QStringLiteral("x1")).toDouble(0.0);
        spec.y1 = object.value(QStringLiteral("y1")).toDouble(0.0);
        spec.x2 = object.value(QStringLiteral("x2")).toDouble(1.0);
        spec.y2 = object.value(QStringLiteral("y2")).toDouble(1.0);
    } else if (kind == QLatin1String("function")) {
        spec.kind = Kind::Function;
        spec.fn = easingFnFromString(object.value(QStringLiteral("fn")).toString());
        spec.amplitude = object.value(QStringLiteral("amplitude")).toDouble(1.0);
        spec.period = object.value(QStringLiteral("period")).toDouble(0.3);
    }
    return spec;
}

QString EasingSpec::toCssString() const
{
    switch (kind) {
    case Kind::Hold:
        return QStringLiteral("steps(1)");
    case Kind::Bezier:
        return QStringLiteral("cubic-bezier(%1, %2, %3, %4)")
            .arg(formatNumber(x1), formatNumber(y1), formatNumber(x2), formatNumber(y2));
    case Kind::Function:
        return QStringLiteral("%1(%2, %3)")
            .arg(easingFnToString(fn), formatNumber(amplitude), formatNumber(period));
    case Kind::Linear:
        break;
    }
    return QStringLiteral("linear");
}

std::optional<EasingSpec> EasingSpec::parseCss(const QString &css)
{
    const QString compact = css.simplified().remove(QLatin1Char(' '));
    if (compact == QLatin1String("linear"))
        return EasingSpec{};
    if (compact == QLatin1String("steps(1)")) {
        EasingSpec spec;
        spec.kind = Kind::Hold;
        return spec;
    }

    const QString cubicPrefix = QStringLiteral("cubic-bezier(");
    if (compact.startsWith(cubicPrefix) || !compact.contains(QLatin1Char('('))) {
        QString numbers = compact;
        if (compact.startsWith(cubicPrefix)) {
            if (!compact.endsWith(QLatin1Char(')')))
                return std::nullopt;
            numbers = compact.mid(cubicPrefix.size(), compact.size() - cubicPrefix.size() - 1);
        }
        const std::optional<QList<double>> values = parseNumbers(numbers, 4);
        if (!values)
            return std::nullopt;
        const QList<double> &v = *values;
        if (v[0] < 0.0 || v[0] > 1.0 || v[2] < 0.0 || v[2] > 1.0)
            return std::nullopt;
        return bezierSpec(v[0], v[1], v[2], v[3]);
    }

    const qsizetype open = compact.indexOf(QLatin1Char('('));
    if (open <= 0 || !compact.endsWith(QLatin1Char(')')))
        return std::nullopt;
    const EasingFn fn = easingFnFromString(compact.left(open));
    if (fn == EasingFn::None)
        return std::nullopt;
    const std::optional<QList<double>> args =
        parseNumbers(compact.mid(open + 1, compact.size() - open - 2), 2);
    if (!args)
        return std::nullopt;

    EasingSpec spec = functionSpec(fn);
    spec.amplitude = (*args)[0];
    spec.period = (*args)[1];
    return spec;
}

bool EasingSpec::approxEquals(const EasingSpec &other, double tol) const
{
    if (kind != other.kind)
        return false;
    switch (kind) {
    case Kind::Bezier:
        return qAbs(x1 - other.x1) <= tol && qAbs(y1 - other.y1) <= tol
            && qAbs(x2 - other.x2) <= tol && qAbs(y2 - other.y2) <= tol;
    case Kind::Function:
        return fn == other.fn && qAbs(amplitude - other.amplitude) <= tol
            && qAbs(period - other.period) <= tol;
    case Kind::Linear:
    case Kind::Hold:
        break;
    }
    return true;
}

const QList<EasingPreset> &builtinEasingPresets()
{
    static const QList<EasingPreset> presets = [] {
        const QString basic = QStringLiteral("basic");
        QList<EasingPreset> out;
        out.append({QStringLiteral("linear"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Straight")), basic, EasingSpec{}});
        EasingSpec hold;
        hold.kind = EasingSpec::Kind::Hold;
        out.append({QStringLiteral("hold"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Jump")), basic, hold});
        out.append({QStringLiteral("ease"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Ease")), basic, bezierSpec(0.25, 0.1, 0.25, 1.0)});

        out.append({QStringLiteral("sineIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Sine In")), QStringLiteral("sine"), bezierSpec(0.12, 0, 0.39, 0)});
        out.append({QStringLiteral("sineOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Sine Out")), QStringLiteral("sine"), bezierSpec(0.61, 1, 0.88, 1)});
        out.append({QStringLiteral("sineInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Sine In-Out")), QStringLiteral("sine"), bezierSpec(0.37, 0, 0.63, 1)});

        out.append({QStringLiteral("quadIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quad In")), QStringLiteral("quad"), bezierSpec(0.11, 0, 0.5, 0)});
        out.append({QStringLiteral("quadOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quad Out")), QStringLiteral("quad"), bezierSpec(0.5, 1, 0.89, 1)});
        out.append({QStringLiteral("quadInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quad In-Out")), QStringLiteral("quad"), bezierSpec(0.45, 0, 0.55, 1)});

        out.append({QStringLiteral("cubicIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Cubic In")), QStringLiteral("cubic"), bezierSpec(0.32, 0, 0.67, 0)});
        out.append({QStringLiteral("cubicOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Cubic Out")), QStringLiteral("cubic"), bezierSpec(0.33, 1, 0.68, 1)});
        out.append({QStringLiteral("cubicInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Cubic In-Out")), QStringLiteral("cubic"), bezierSpec(0.65, 0, 0.35, 1)});

        out.append({QStringLiteral("quartIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quart In")), QStringLiteral("quart"), bezierSpec(0.5, 0, 0.75, 0)});
        out.append({QStringLiteral("quartOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quart Out")), QStringLiteral("quart"), bezierSpec(0.25, 1, 0.5, 1)});
        out.append({QStringLiteral("quartInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quart In-Out")), QStringLiteral("quart"), bezierSpec(0.76, 0, 0.24, 1)});

        out.append({QStringLiteral("quintIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quint In")), QStringLiteral("quint"), bezierSpec(0.64, 0, 0.78, 0)});
        out.append({QStringLiteral("quintOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quint Out")), QStringLiteral("quint"), bezierSpec(0.22, 1, 0.36, 1)});
        out.append({QStringLiteral("quintInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Quint In-Out")), QStringLiteral("quint"), bezierSpec(0.83, 0, 0.17, 1)});

        out.append({QStringLiteral("expoIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Expo In")), QStringLiteral("expo"), bezierSpec(0.7, 0, 0.84, 0)});
        out.append({QStringLiteral("expoOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Expo Out")), QStringLiteral("expo"), bezierSpec(0.16, 1, 0.3, 1)});
        out.append({QStringLiteral("expoInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Expo In-Out")), QStringLiteral("expo"), bezierSpec(0.87, 0, 0.13, 1)});

        out.append({QStringLiteral("circIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Circ In")), QStringLiteral("circ"), bezierSpec(0.55, 0, 1, 0.45)});
        out.append({QStringLiteral("circOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Circ Out")), QStringLiteral("circ"), bezierSpec(0, 0.55, 0.45, 1)});
        out.append({QStringLiteral("circInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Circ In-Out")), QStringLiteral("circ"), bezierSpec(0.85, 0, 0.15, 1)});

        out.append({QStringLiteral("backIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Back In")), QStringLiteral("back"), bezierSpec(0.36, 0, 0.66, -0.56)});
        out.append({QStringLiteral("backOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Back Out")), QStringLiteral("back"), bezierSpec(0.34, 1.56, 0.64, 1)});
        out.append({QStringLiteral("backInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Back In-Out")), QStringLiteral("back"), bezierSpec(0.68, -0.6, 0.32, 1.6)});

        out.append({QStringLiteral("elasticIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Elastic In")), QStringLiteral("elastic"), functionSpec(EasingFn::ElasticIn)});
        out.append({QStringLiteral("elasticOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Elastic Out")), QStringLiteral("elastic"), functionSpec(EasingFn::ElasticOut)});
        out.append({QStringLiteral("elasticInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Elastic In-Out")), QStringLiteral("elastic"), functionSpec(EasingFn::ElasticInOut)});

        out.append({QStringLiteral("bounceIn"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Bounce In")), QStringLiteral("bounce"), functionSpec(EasingFn::BounceIn)});
        out.append({QStringLiteral("bounceOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Bounce Out")), QStringLiteral("bounce"), functionSpec(EasingFn::BounceOut)});
        out.append({QStringLiteral("bounceInOut"), QString::fromLatin1(QT_TRANSLATE_NOOP("EasingPresets", "Bounce In-Out")), QStringLiteral("bounce"), functionSpec(EasingFn::BounceInOut)});
        return out;
    }();
    return presets;
}

const EasingPreset *findBuiltinEasingPreset(const QString &id)
{
    for (const EasingPreset &preset : builtinEasingPresets()) {
        if (preset.id == id)
            return &preset;
    }
    return nullptr;
}

QString matchBuiltinEasingPreset(const EasingSpec &spec)
{
    for (const EasingPreset &preset : builtinEasingPresets()) {
        if (preset.spec.approxEquals(spec))
            return preset.id;
    }
    return {};
}

QVector<QPointF> sampleEasing(const EasingSpec &spec, int n)
{
    QVector<QPointF> points;
    points.reserve(n + 1);
    for (int i = 0; i <= n; ++i) {
        const double x = static_cast<double>(i) / n;
        double y = x;
        switch (spec.kind) {
        case EasingSpec::Kind::Bezier:
            y = cubicBezier(0.0, spec.y1, spec.y2, 1.0, bezierParameterForX(0.0, spec.x1, spec.x2, 1.0, x));
            break;
        case EasingSpec::Kind::Hold:
            y = i == n ? 1.0 : 0.0;
            break;
        case EasingSpec::Kind::Function:
            y = evaluateEasingFn(spec.fn, x, spec.amplitude, spec.period);
            break;
        case EasingSpec::Kind::Linear:
            break;
        }
        points.append(QPointF(x, y));
    }
    return points;
}

} // namespace drift
