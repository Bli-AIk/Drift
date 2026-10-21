#include "engine/gpu/effects/LookupTextures.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointF>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <vector>

namespace drift {
namespace {

constexpr int kTexels = 256;

using Rgba = std::array<double, 4>;

bool parseHexRgba(const QString &hex, Rgba *out)
{
    if (!hex.startsWith(QLatin1Char('#')) || (hex.size() != 7 && hex.size() != 9))
        return false;
    *out = {0.0, 0.0, 0.0, 1.0};
    bool ok = false;
    for (int channel = 0; channel < 3; ++channel) {
        const unsigned value = hex.mid(1 + 2 * channel, 2).toUInt(&ok, 16);
        if (!ok)
            return false;
        (*out)[size_t(channel)] = value / 255.0;
    }
    if (hex.size() == 9) {
        const unsigned alpha = hex.mid(7, 2).toUInt(&ok, 16);
        if (!ok)
            return false;
        (*out)[3] = alpha / 255.0;
    }
    return true;
}

// The easing applied to a segment's 0..1 fraction. Keyed by the left key, as Forge does.
double applyEase(const QString &ease, double k)
{
    if (ease == QLatin1String("smooth"))
        return k * k * (3.0 - 2.0 * k);
    if (ease == QLatin1String("in"))
        return k * k * k;
    if (ease == QLatin1String("out"))
        return 1.0 - (1.0 - k) * (1.0 - k) * (1.0 - k);
    if (ease == QLatin1String("hold"))
        return 0.0;
    return k;
}

uint8_t toByte(double v)
{
    return uint8_t(std::lround(std::clamp(v, 0.0, 1.0) * 255.0));
}

} // namespace

double evalMonotoneSpline(const std::vector<QPointF> &keys, double x)
{
    const size_t n = keys.size();
    if (n == 0)
        return 0.0;
    if (x <= keys.front().x())
        return keys.front().y();
    if (x >= keys.back().x())
        return keys.back().y();

    const size_t segments = n - 1;
    std::vector<double> d(segments);
    for (size_t j = 0; j < segments; ++j) {
        const double dx = keys[j + 1].x() - keys[j].x();
        d[j] = dx > 0.0 ? (keys[j + 1].y() - keys[j].y()) / dx : 0.0;
    }
    std::vector<double> m(n);
    m.front() = d.front();
    m.back() = d.back();
    for (size_t j = 1; j < segments; ++j)
        m[j] = d[j - 1] * d[j] <= 0.0 ? 0.0 : (d[j - 1] + d[j]) / 2.0;
    for (size_t j = 0; j < segments; ++j) {
        if (d[j] == 0.0) {
            m[j] = 0.0;
            m[j + 1] = 0.0;
            continue;
        }
        const double a = m[j] / d[j];
        const double b = m[j + 1] / d[j];
        const double s = a * a + b * b;
        if (s > 9.0) {
            const double t = 3.0 / std::sqrt(s);
            m[j] = t * a * d[j];
            m[j + 1] = t * b * d[j];
        }
    }

    size_t k = 0;
    while (k + 2 < n && keys[k + 1].x() <= x)
        ++k;
    const double h = keys[k + 1].x() - keys[k].x();
    const double t = (x - keys[k].x()) / h;
    const double t2 = t * t;
    const double t3 = t2 * t;
    const double h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
    const double h10 = t3 - 2.0 * t2 + t;
    const double h01 = -2.0 * t3 + 3.0 * t2;
    const double h11 = t3 - t2;
    const double y = h00 * keys[k].y() + h10 * h * m[k] + h01 * keys[k + 1].y() + h11 * h * m[k + 1];
    return std::clamp(y, 0.0, 1.0);
}

QByteArray bakeGradient(const QString &json)
{
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &error);
    if (error.error != QJsonParseError::NoError || !doc.isArray())
        return {};

    struct Stop
    {
        double position;
        Rgba rgba;
    };
    std::vector<Stop> stops;
    for (const QJsonValue &value : doc.array()) {
        const QJsonObject stop = value.toObject();
        Rgba rgba{};
        if (!parseHexRgba(stop.value(QStringLiteral("color")).toString(), &rgba))
            return {};
        stops.push_back({stop.value(QStringLiteral("position")).toDouble(), rgba});
    }
    if (stops.empty())
        return {};
    std::stable_sort(stops.begin(), stops.end(),
                     [](const Stop &a, const Stop &b) { return a.position < b.position; });

    QByteArray out(kTexels * 4, Qt::Uninitialized);
    for (int i = 0; i < kTexels; ++i) {
        const double t = i / 255.0;
        Rgba c{};
        if (t <= stops.front().position) {
            c = stops.front().rgba;
        } else if (t >= stops.back().position) {
            c = stops.back().rgba;
        } else {
            const auto right = std::lower_bound(stops.begin(), stops.end(), t,
                                                [](const Stop &s, double v) { return s.position < v; });
            const Stop &left = *(right - 1);
            const double k = (t - left.position) / (right->position - left.position);
            for (size_t channel = 0; channel < 4; ++channel)
                c[channel] = left.rgba[channel] + (right->rgba[channel] - left.rgba[channel]) * k;
        }
        for (size_t channel = 0; channel < 4; ++channel)
            out[i * 4 + int(channel)] = char(toByte(c[channel]));
    }
    return out;
}

QByteArray bakeCurve(const QString &json)
{
    QJsonParseError error;
    const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &error);
    if (error.error != QJsonParseError::NoError || !doc.isArray())
        return {};

    struct Key
    {
        double x;
        double y;
        QString ease;
    };
    std::vector<Key> keys;
    for (const QJsonValue &value : doc.array()) {
        const QJsonObject key = value.toObject();
        keys.push_back({key.value(QStringLiteral("x")).toDouble(),
                        key.value(QStringLiteral("y")).toDouble(),
                        key.value(QStringLiteral("ease")).toString(QStringLiteral("linear"))});
    }
    if (keys.empty())
        return {};
    std::stable_sort(keys.begin(), keys.end(), [](const Key &a, const Key &b) { return a.x < b.x; });

    std::vector<QPointF> points;
    points.reserve(keys.size());
    for (const Key &key : keys)
        points.emplace_back(key.x, key.y);

    QByteArray out(kTexels * 4, Qt::Uninitialized);
    for (int i = 0; i < kTexels; ++i) {
        const double t = i / 255.0;
        double y = 0.0;
        if (t <= keys.front().x) {
            y = keys.front().y;
        } else if (t >= keys.back().x) {
            y = keys.back().y;
        } else {
            const auto right = std::lower_bound(keys.begin(), keys.end(), t,
                                                [](const Key &k, double v) { return k.x < v; });
            const Key &left = *(right - 1);
            if (left.ease == QLatin1String("spline")) {
                y = evalMonotoneSpline(points, t);
            } else {
                const double k = (t - left.x) / (right->x - left.x);
                y = left.y + (right->y - left.y) * applyEase(left.ease, k);
            }
        }
        const char value = char(toByte(y));
        out[i * 4 + 0] = value;
        out[i * 4 + 1] = value;
        out[i * 4 + 2] = value;
        out[i * 4 + 3] = char(255);
    }
    return out;
}

} // namespace drift
