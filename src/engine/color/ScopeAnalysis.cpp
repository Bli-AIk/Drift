#include "engine/color/ScopeAnalysis.h"

#include <QColor>
#include <QPainter>
#include <QPointF>
#include <QPolygonF>

#include <algorithm>
#include <cmath>
#include <vector>

namespace drift {
namespace {

constexpr double kLumaR = 0.2126;
constexpr double kLumaG = 0.7152;
constexpr double kLumaB = 0.0722;
constexpr double kCbScale = 1.8556;
constexpr double kCrScale = 1.5748;

int lumaOf(QRgb px)
{
    return qRound(kLumaR * qRed(px) + kLumaG * qGreen(px) + kLumaB * qBlue(px));
}

// Each pixel's (Cb, Cr) in [-0.5, 0.5] on BT.709 scales.
QPointF chromaOf(double r, double g, double b)
{
    const double y = kLumaR * r + kLumaG * g + kLumaB * b;
    return {(b - y) / kCbScale, (r - y) / kCrScale};
}

QImage blankImage(QSize size)
{
    QImage img(size, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    return img;
}

} // namespace

HistogramData computeHistogram(const QImage &frame)
{
    HistogramData h;
    const QImage img = frame.convertToFormat(QImage::Format_RGB32);
    for (int row = 0; row < img.height(); ++row) {
        const QRgb *px = reinterpret_cast<const QRgb *>(img.constScanLine(row));
        for (int x = 0; x < img.width(); ++x) {
            h.r[qRed(px[x])]++;
            h.g[qGreen(px[x])]++;
            h.b[qBlue(px[x])]++;
            h.y[lumaOf(px[x])]++;
        }
    }
    return h;
}

QImage renderHistogram(const HistogramData &data, QSize size)
{
    QImage img = blankImage(size);

    // The ends are where clipped pixels pile up; leaving them out keeps the rest readable.
    quint32 peak = 1;
    for (int i = 1; i < 255; ++i) {
        peak = std::max({peak, data.r[i], data.g[i], data.b[i], data.y[i]});
    }

    const int w = size.width();
    const int h = size.height();
    auto outline = [&](const std::array<quint32, 256> &bins) {
        QPolygonF poly;
        poly << QPointF(0, h);
        for (int x = 0; x < w; ++x) {
            const double v = std::min(1.0, double(bins[x * 256 / w]) / peak);
            poly << QPointF(x, h - v * h);
        }
        poly << QPointF(w - 1, h);
        return poly;
    };

    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing, false);
    p.setCompositionMode(QPainter::CompositionMode_Plus);
    p.setPen(Qt::NoPen);
    p.setBrush(QColor(255, 60, 60, 110));
    p.drawPolygon(outline(data.r));
    p.setBrush(QColor(60, 255, 60, 110));
    p.drawPolygon(outline(data.g));
    p.setBrush(QColor(70, 120, 255, 110));
    p.drawPolygon(outline(data.b));

    p.setCompositionMode(QPainter::CompositionMode_SourceOver);
    p.setBrush(Qt::NoBrush);
    p.setPen(QColor(220, 220, 220, 200));
    QPolygonF luma = outline(data.y);
    luma.remove(0);
    luma.remove(luma.size() - 1);
    p.drawPolyline(luma);
    return img;
}

QImage renderWaveform(const QImage &frame, bool parade, QSize size)
{
    const QImage img = frame.convertToFormat(QImage::Format_RGB32);
    const int w = size.width();
    const int h = size.height();
    const int third = std::max(1, w / 3);
    const int cols = parade ? third : w;

    // Source column -> waveform column, and value -> row (0 at the bottom).
    std::vector<int> colOf(std::max(1, img.width()));
    for (int x = 0; x < img.width(); ++x)
        colOf[x] = std::min(cols - 1, x * cols / img.width());
    std::array<int, 256> rowOf{};
    for (int v = 0; v < 256; ++v)
        rowOf[v] = qRound((h - 1) * (1.0 - v / 255.0));

    std::vector<float> counts(size_t(w) * h, 0.f);
    for (int sy = 0; sy < img.height(); ++sy) {
        const QRgb *px = reinterpret_cast<const QRgb *>(img.constScanLine(sy));
        for (int sx = 0; sx < img.width(); ++sx) {
            if (parade) {
                const int values[3] = {qRed(px[sx]), qGreen(px[sx]), qBlue(px[sx])};
                for (int c = 0; c < 3; ++c) {
                    const int col = std::min(w - 1, c * third + colOf[sx]);
                    counts[size_t(rowOf[values[c]]) * w + col] += 1.f;
                }
            } else {
                counts[size_t(rowOf[lumaOf(px[sx])]) * w + colOf[sx]] += 1.f;
            }
        }
    }

    float peak = 1.f;
    for (float c : counts)
        peak = std::max(peak, c);
    const float logPeak = std::log1p(peak);

    QImage out = blankImage(size);
    for (int row = 0; row < h; ++row) {
        for (int col = 0; col < w; ++col) {
            const float c = counts[size_t(row) * w + col];
            if (c <= 0.f)
                continue;
            const float intensity = std::log1p(c) / logPeak;
            QColor tint(200, 255, 200);
            if (parade) {
                const int channel = std::min(2, col / third);
                tint = channel == 0   ? QColor(255, 70, 70)
                       : channel == 1 ? QColor(70, 255, 70)
                                      : QColor(90, 140, 255);
            }
            tint.setAlphaF(intensity);
            out.setPixelColor(col, row, tint);
        }
    }

    QPainter p(&out);
    p.setPen(QColor(255, 255, 255, 40));
    for (double frac : {0.0, 0.25, 0.5, 0.75, 1.0}) {
        const double y = std::round((h - 1) * (1.0 - frac)) + 0.5;
        p.drawLine(QPointF(0, y), QPointF(w - 1, y));
    }
    return out;
}

QImage renderVectorscope(const QImage &frame, QSize size)
{
    const QImage img = frame.convertToFormat(QImage::Format_RGB32);
    const int w = size.width();
    const int h = size.height();
    const int side = std::max(1, std::min(w, h));
    const double half = side / 2.0;
    const double cx = w / 2.0;
    const double cy = h / 2.0;

    // Map Cb/Cr in [-0.5, 0.5] onto the square, with Cr pointing up.
    auto binOf = [&](double v) { return std::clamp(int(std::floor((v + 0.5) * side)), 0, side - 1); };

    const size_t bins = size_t(side) * side;
    std::vector<float> count(bins, 0.f);
    std::vector<float> sum(bins * 3, 0.f);
    for (int sy = 0; sy < img.height(); ++sy) {
        const QRgb *px = reinterpret_cast<const QRgb *>(img.constScanLine(sy));
        for (int sx = 0; sx < img.width(); ++sx) {
            const double r = qRed(px[sx]) / 255.0;
            const double g = qGreen(px[sx]) / 255.0;
            const double b = qBlue(px[sx]) / 255.0;
            const QPointF c = chromaOf(r, g, b);
            const int bx = binOf(c.x());
            const int by = side - 1 - binOf(c.y());
            const size_t i = size_t(by) * side + bx;
            count[i] += 1.f;
            sum[i * 3] += float(r);
            sum[i * 3 + 1] += float(g);
            sum[i * 3 + 2] += float(b);
        }
    }

    float peak = 1.f;
    for (float c : count)
        peak = std::max(peak, c);
    const float logPeak = std::log1p(peak);

    QImage out = blankImage(size);
    for (int by = 0; by < side; ++by) {
        for (int bx = 0; bx < side; ++bx) {
            const size_t i = size_t(by) * side + bx;
            if (count[i] <= 0.f)
                continue;
            const float n = count[i];
            QColor tint(int(sum[i * 3] / n * 255), int(sum[i * 3 + 1] / n * 255),
                        int(sum[i * 3 + 2] / n * 255));
            tint.setAlphaF(std::log1p(n) / logPeak);
            out.setPixelColor(int(cx - half) + bx, int(cy - half) + by, tint);
        }
    }

    QPainter p(&out);
    p.setRenderHint(QPainter::Antialiasing, true);
    const QColor grat(255, 255, 255, 60);
    p.setPen(grat);
    p.setBrush(Qt::NoBrush);
    p.drawEllipse(QPointF(cx, cy), half - 0.5, half - 0.5);
    p.drawLine(QPointF(cx, cy - half), QPointF(cx, cy + half));
    p.drawLine(QPointF(cx - half, cy), QPointF(cx + half, cy));

    // Targets at 75% for the primaries and secondaries, and the skin-tone line from the same formula.
    const double sat = 0.75;
    const double targets[6][3] = {
        {sat, 0, 0}, {sat, 0, sat}, {0, 0, sat}, {0, sat, sat}, {0, sat, 0}, {sat, sat, 0},
    };
    const double box = std::max(4.0, side / 32.0);
    for (const auto &t : targets) {
        const QPointF c = chromaOf(t[0], t[1], t[2]);
        const QPointF at(cx + c.x() * side, cy - c.y() * side);
        p.drawRect(QRectF(at.x() - box / 2, at.y() - box / 2, box, box));
    }

    const QPointF skin = chromaOf(224 / 255.0, 172 / 255.0, 138 / 255.0);
    const double skinLen = std::hypot(skin.x(), skin.y());
    if (skinLen > 0.0) {
        const QPointF dir(skin.x() / skinLen, -skin.y() / skinLen);
        p.drawLine(QPointF(cx, cy), QPointF(cx, cy) + dir * half);
    }
    return out;
}

} // namespace drift
