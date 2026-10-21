#include "engine/color/CubeLut.h"

#include <QDebug>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QMutex>
#include <QMutexLocker>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <utility>

namespace drift {
namespace {

constexpr qint64 kMaxFileBytes = 32LL * 1024 * 1024;
constexpr int kMinSize = 2;
constexpr int kMax3DSize = 256;
constexpr int kMax1DSize = 65536;
constexpr int kBakeSize = 33;

bool fail(QString *error, const QString &message)
{
    if (error)
        *error = message;
    return false;
}

bool parseIntIn(const QString &token, int lo, int hi, int *out)
{
    bool ok = false;
    const int value = token.toInt(&ok);
    if (!ok || value < lo || value > hi)
        return false;
    *out = value;
    return true;
}

bool parseFiniteDouble(const QString &token, double *out)
{
    bool ok = false;
    const double value = token.toDouble(&ok);
    if (!ok || !std::isfinite(value))
        return false;
    *out = value;
    return true;
}

// Linear interpolation along a 1D curve stored as n rows of three channels.
double sampleCurve(const std::vector<double> &rows, size_t n, int channel, double x)
{
    const double pos = std::clamp(x, 0.0, 1.0) * double(n - 1);
    const size_t i0 = std::min(size_t(pos), n - 2);
    const double f = pos - double(i0);
    return rows[i0 * 3 + size_t(channel)] * (1.0 - f) + rows[(i0 + 1) * 3 + size_t(channel)] * f;
}

uint8_t toByte(double v)
{
    return uint8_t(std::lround(std::clamp(v, 0.0, 1.0) * 255.0));
}

void sampleTrilinear(const CubeLut &lut, const float in[3], float out[3])
{
    const int n = lut.size;
    int base[3];
    float frac[3];
    for (int c = 0; c < 3; ++c) {
        const float t = (in[c] - lut.domainMin[c]) / (lut.domainMax[c] - lut.domainMin[c]);
        const float pos = std::clamp(t, 0.0f, 1.0f) * float(n - 1);
        base[c] = std::min(int(pos), n - 2);
        frac[c] = pos - float(base[c]);
    }
    out[0] = out[1] = out[2] = 0.0f;
    for (int corner = 0; corner < 8; ++corner) {
        float weight = 1.0f;
        int idx[3];
        for (int c = 0; c < 3; ++c) {
            const bool high = ((corner >> c) & 1) != 0;
            weight *= high ? frac[c] : 1.0f - frac[c];
            idx[c] = base[c] + (high ? 1 : 0);
        }
        const size_t offset = ((size_t(idx[2]) * size_t(n) + size_t(idx[1])) * size_t(n) + size_t(idx[0])) * 3;
        for (int c = 0; c < 3; ++c)
            out[c] += weight * lut.rgb[offset + size_t(c)];
    }
}

QMutex &resolverMutex()
{
    static QMutex mutex;
    return mutex;
}

LutResolver &resolverSlot()
{
    static LutResolver resolver;
    return resolver;
}

struct CachedLut
{
    qint64 modifiedMs = 0;
    // Both null: the file failed to parse at this mtime.
    std::shared_ptr<const CubeLut> lut;
    std::shared_ptr<const QByteArray> baked;
};

QMutex &cacheMutex()
{
    static QMutex mutex;
    return mutex;
}

QHash<QString, CachedLut> &cacheSlot()
{
    static QHash<QString, CachedLut> cache;
    return cache;
}

} // namespace

bool CubeLut::isValid() const
{
    if (size < kMinSize || size > kMax3DSize)
        return false;
    const size_t n = size_t(size);
    return rgb.size() == n * n * n * 3;
}

bool parseCube(const QByteArray &data, CubeLut *out, QString *error)
{
    int size3d = 0;
    int size1d = 0;
    QString title;
    double domainMin[3] = {0.0, 0.0, 0.0};
    double domainMax[3] = {1.0, 1.0, 1.0};
    std::vector<double> rows;

    for (const QByteArray &rawLine : data.split('\n')) {
        const QString line = QString::fromUtf8(rawLine).trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
            continue;

        if (line.at(0).isLetter()) {
            const QStringList tokens = line.simplified().split(QLatin1Char(' '));
            const QString &keyword = tokens.first();
            if (keyword == QLatin1String("TITLE")) {
                const int open = line.indexOf(QLatin1Char('"'));
                const int close = line.lastIndexOf(QLatin1Char('"'));
                title = (open >= 0 && close > open) ? line.mid(open + 1, close - open - 1) : QString();
            } else if (keyword == QLatin1String("LUT_3D_SIZE")) {
                if (tokens.size() != 2 || !parseIntIn(tokens.at(1), kMinSize, kMax3DSize, &size3d))
                    return fail(error, QStringLiteral("invalid LUT_3D_SIZE"));
            } else if (keyword == QLatin1String("LUT_1D_SIZE")) {
                if (tokens.size() != 2 || !parseIntIn(tokens.at(1), kMinSize, kMax1DSize, &size1d))
                    return fail(error, QStringLiteral("invalid LUT_1D_SIZE"));
            } else if (keyword == QLatin1String("DOMAIN_MIN") || keyword == QLatin1String("DOMAIN_MAX")) {
                double *target = keyword == QLatin1String("DOMAIN_MIN") ? domainMin : domainMax;
                if (tokens.size() != 4)
                    return fail(error, QStringLiteral("%1 needs three values").arg(keyword));
                for (int c = 0; c < 3; ++c) {
                    if (!parseFiniteDouble(tokens.at(c + 1), &target[c]))
                        return fail(error, QStringLiteral("%1 has an invalid value").arg(keyword));
                }
            }
            continue;
        }

        const QStringList tokens = line.simplified().split(QLatin1Char(' '));
        if (tokens.size() != 3)
            return fail(error, QStringLiteral("malformed data row '%1'").arg(line));
        for (const QString &token : tokens) {
            double value = 0.0;
            if (!parseFiniteDouble(token, &value))
                return fail(error, QStringLiteral("invalid number '%1'").arg(token));
            rows.push_back(value);
        }
    }

    if ((size3d == 0) == (size1d == 0))
        return fail(error, size3d ? QStringLiteral("file has both LUT_3D_SIZE and LUT_1D_SIZE")
                                  : QStringLiteral("file has no LUT_3D_SIZE or LUT_1D_SIZE"));

    for (int c = 0; c < 3; ++c) {
        if (!(domainMax[c] > domainMin[c]))
            return fail(error, QStringLiteral("DOMAIN_MAX must be greater than DOMAIN_MIN"));
    }

    CubeLut lut;
    lut.title = title;
    if (size3d) {
        const size_t n = size_t(size3d);
        if (rows.size() != n * n * n * 3)
            return fail(error, QStringLiteral("expected %1 data rows, found %2")
                                   .arg(n * n * n).arg(rows.size() / 3));
        lut.size = size3d;
        for (int c = 0; c < 3; ++c) {
            lut.domainMin[c] = float(domainMin[c]);
            lut.domainMax[c] = float(domainMax[c]);
        }
        lut.rgb.reserve(rows.size());
        for (double v : rows)
            lut.rgb.push_back(float(v));
    } else {
        const size_t n = size_t(size1d);
        if (rows.size() != n * 3)
            return fail(error, QStringLiteral("expected %1 data rows, found %2")
                                   .arg(n).arg(rows.size() / 3));
        lut.size = kBakeSize;
        lut.rgb.resize(size_t(kBakeSize) * kBakeSize * kBakeSize * 3);
        for (int b = 0; b < kBakeSize; ++b) {
            for (int g = 0; g < kBakeSize; ++g) {
                for (int r = 0; r < kBakeSize; ++r) {
                    const double in[3] = {r / double(kBakeSize - 1), g / double(kBakeSize - 1),
                                          b / double(kBakeSize - 1)};
                    const size_t offset = ((size_t(b) * kBakeSize + size_t(g)) * kBakeSize + size_t(r)) * 3;
                    for (int c = 0; c < 3; ++c)
                        lut.rgb[offset + size_t(c)] = float(sampleCurve(
                            rows, n, c, (in[c] - domainMin[c]) / (domainMax[c] - domainMin[c])));
                }
            }
        }
    }
    *out = std::move(lut);
    return true;
}

bool loadCubeFile(const QString &path, CubeLut *out, QString *error)
{
    const QFileInfo info(path);
    if (!info.isFile())
        return fail(error, QStringLiteral("not a file: %1").arg(path));
    if (info.size() > kMaxFileBytes)
        return fail(error, QStringLiteral("file is larger than 32 MiB: %1").arg(path));
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return fail(error, QStringLiteral("cannot open %1").arg(path));
    return parseCube(file.readAll(), out, error);
}

CubeLut identityLut(int n)
{
    CubeLut lut;
    lut.size = n;
    lut.rgb.resize(size_t(n) * n * n * 3);
    for (int b = 0; b < n; ++b) {
        for (int g = 0; g < n; ++g) {
            for (int r = 0; r < n; ++r) {
                const size_t offset = ((size_t(b) * n + size_t(g)) * n + size_t(r)) * 3;
                lut.rgb[offset + 0] = float(r) / float(n - 1);
                lut.rgb[offset + 1] = float(g) / float(n - 1);
                lut.rgb[offset + 2] = float(b) / float(n - 1);
            }
        }
    }
    return lut;
}

CubeLut resampledLut(const CubeLut &lut, int n)
{
    CubeLut out;
    if (!lut.isValid())
        return out;
    out.size = n;
    out.title = lut.title;
    out.rgb.resize(size_t(n) * n * n * 3);
    for (int b = 0; b < n; ++b) {
        for (int g = 0; g < n; ++g) {
            for (int r = 0; r < n; ++r) {
                const float in[3] = {float(r) / float(n - 1), float(g) / float(n - 1), float(b) / float(n - 1)};
                const size_t offset = ((size_t(b) * n + size_t(g)) * n + size_t(r)) * 3;
                sampleTrilinear(lut, in, &out.rgb[offset]);
            }
        }
    }
    return out;
}

QByteArray bakeTiledRgba8(const CubeLut &lut)
{
    if (!lut.isValid())
        return {};
    const size_t n = size_t(lut.size);
    QByteArray out(int(n * n * n * 4), Qt::Uninitialized);
    for (size_t g = 0; g < n; ++g) {
        for (size_t b = 0; b < n; ++b) {
            for (size_t r = 0; r < n; ++r) {
                const size_t src = ((b * n + g) * n + r) * 3;
                const size_t x = b * n + r;
                const size_t dst = (g * n * n + x) * 4;
                for (size_t c = 0; c < 3; ++c)
                    out[int(dst + c)] = char(toByte(lut.rgb[src + c]));
                out[int(dst + 3)] = char(255);
            }
        }
    }
    return out;
}

QRgb applyLut(const CubeLut &lut, QRgb px, float amount)
{
    if (!lut.isValid())
        return px;
    const float in[3] = {float(qRed(px)) / 255.0f, float(qGreen(px)) / 255.0f, float(qBlue(px)) / 255.0f};
    float mapped[3];
    sampleTrilinear(lut, in, mapped);
    const float t = std::clamp(amount, 0.0f, 1.0f);
    int channels[3];
    for (int c = 0; c < 3; ++c) {
        const float value = in[c] * (1.0f - t) + mapped[c] * t;
        channels[c] = int(std::lround(std::clamp(value, 0.0f, 1.0f) * 255.0f));
    }
    return qRgba(channels[0], channels[1], channels[2], qAlpha(px));
}

void setLutResolver(LutResolver resolver)
{
    QMutexLocker lock(&resolverMutex());
    resolverSlot() = std::move(resolver);
}

QString resolveLutPath(const QString &lookId)
{
    LutResolver resolver;
    {
        QMutexLocker lock(&resolverMutex());
        resolver = resolverSlot();
    }
    return resolver ? resolver(lookId) : QString();
}

namespace {

CachedLut cachedLutForId(const QString &lookId)
{
    const QString path = resolveLutPath(lookId);
    if (path.isEmpty())
        return {};
    const QFileInfo info(path);
    if (!info.isFile())
        return {};
    const qint64 modifiedMs = info.lastModified().toMSecsSinceEpoch();
    {
        QMutexLocker lock(&cacheMutex());
        const auto it = cacheSlot().constFind(path);
        if (it != cacheSlot().constEnd() && it->modifiedMs == modifiedMs)
            return *it;
    }

    CachedLut entry;
    entry.modifiedMs = modifiedMs;
    CubeLut lut;
    QString error;
    if (loadCubeFile(path, &lut, &error)) {
        auto resampled = std::make_shared<const CubeLut>(resampledLut(lut, kBakeSize));
        entry.baked = std::make_shared<const QByteArray>(bakeTiledRgba8(*resampled));
        entry.lut = std::move(resampled);
    } else {
        qWarning("CubeLut: cannot use look '%s': %s", qPrintable(lookId), qPrintable(error));
    }

    QMutexLocker lock(&cacheMutex());
    cacheSlot().insert(path, entry);
    return entry;
}

} // namespace

std::shared_ptr<const QByteArray> bakedLutForId(const QString &lookId)
{
    return cachedLutForId(lookId).baked;
}

std::shared_ptr<const CubeLut> resampledLutForId(const QString &lookId)
{
    return cachedLutForId(lookId).lut;
}

} // namespace drift
