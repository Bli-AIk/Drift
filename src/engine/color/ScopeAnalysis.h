#pragma once

#include <array>

#include <QImage>
#include <QSize>
#include <QtGlobal>

namespace drift {

struct HistogramData
{
    std::array<quint32, 256> r{}, g{}, b{}, y{};
};

HistogramData computeHistogram(const QImage &frame);
QImage renderHistogram(const HistogramData &data, QSize size = {256, 128});
QImage renderWaveform(const QImage &frame, bool parade, QSize size = {256, 256});
QImage renderVectorscope(const QImage &frame, QSize size = {256, 256});

} // namespace drift
