#include "ImageSequence.h"

#include "MediaAsset.h"

#include <QFile>
#include <QFileInfo>
#include <QMap>
#include <QRegularExpression>
#include <algorithm>
#include <numeric>
#include <cmath>

namespace drift {

namespace {

// The pattern around its single conversion, with %% already collapsed to %.
struct SplitPattern {
    QString head;
    QString tail;
    int width = 0; // 0 for a bare %d
};

std::optional<SplitPattern> splitPattern(const QString &pattern)
{
    SplitPattern out;
    bool found = false;
    QString *cur = &out.head;
    for (int i = 0; i < pattern.size(); ++i) {
        const QChar c = pattern[i];
        if (c != QLatin1Char('%')) {
            cur->append(c);
            continue;
        }
        if (i + 1 >= pattern.size())
            return std::nullopt;
        if (pattern[i + 1] == QLatin1Char('%')) {
            cur->append(QLatin1Char('%'));
            ++i;
            continue;
        }
        if (found)
            return std::nullopt;
        int j = i + 1;
        int width = 0;
        if (pattern[j] == QLatin1Char('0')) {
            ++j;
            int digitsStart = j;
            while (j < pattern.size() && pattern[j].isDigit())
                ++j;
            if (j == digitsStart)
                return std::nullopt;
            width = pattern.mid(digitsStart, j - digitsStart).toInt();
        }
        if (j >= pattern.size() || pattern[j] != QLatin1Char('d'))
            return std::nullopt;
        out.width = width;
        found = true;
        cur = &out.tail;
        i = j;
    }
    if (!found)
        return std::nullopt;
    return out;
}

QString formatNumber(int number, int width)
{
    return QStringLiteral("%1").arg(number, width, 10, QLatin1Char('0'));
}

QString escapePercent(QString s)
{
    return s.replace(QLatin1Char('%'), QStringLiteral("%%"));
}

QString conversionFor(int width)
{
    return width > 0 ? QStringLiteral("%0") + QString::number(width) + QLatin1Char('d')
                     : QStringLiteral("%d");
}

struct Candidate {
    QString path;
    QString dir;
    QString prefix;
    QString digits;
    QString ext;
    int order = 0;
};

} // namespace

bool isImageSequencePath(const QString &path)
{
    return parseImageSequencePath(path).has_value();
}

std::optional<ImageSequence> parseImageSequencePath(const QString &path)
{
    const int hash = path.lastIndexOf(QLatin1Char('#'));
    if (hash <= 0)
        return std::nullopt;

    static const QRegularExpression meta(QStringLiteral("^start=(\\d+)&fps=(\\d+):(\\d+)$"));
    const QRegularExpressionMatch m = meta.match(path.mid(hash + 1));
    if (!m.hasMatch())
        return std::nullopt;

    bool okStart = false, okNum = false, okDen = false;
    ImageSequence seq;
    seq.pattern = path.left(hash);
    seq.start = m.captured(1).toInt(&okStart);
    seq.fpsNum = m.captured(2).toInt(&okNum);
    seq.fpsDen = m.captured(3).toInt(&okDen);
    if (!okStart || !okNum || !okDen || seq.start < 0 || seq.fpsNum <= 0 || seq.fpsDen <= 0)
        return std::nullopt;
    if (!splitPattern(seq.pattern))
        return std::nullopt;
    return seq;
}

QString imageSequencePath(const ImageSequence &seq)
{
    // Concatenated, not arg()-formatted: the pattern's own "%04d" would read as a placeholder.
    return seq.pattern + QStringLiteral("#start=") + QString::number(seq.start) + QStringLiteral("&fps=")
           + QString::number(seq.fpsNum) + QLatin1Char(':') + QString::number(seq.fpsDen);
}

QString imageSequenceFramePath(const ImageSequence &seq, int number)
{
    const auto split = splitPattern(seq.pattern);
    if (!split)
        return {};
    return split->head + formatNumber(number, split->width) + split->tail;
}

QStringList imageSequenceFrames(const ImageSequence &seq, int maxFrames)
{
    QStringList frames;
    for (int n = seq.start; n >= 0; ++n) {
        if (maxFrames > 0 && frames.size() >= maxFrames)
            break;
        const QString file = imageSequenceFramePath(seq, n);
        if (file.isEmpty() || !QFile::exists(file))
            break;
        frames.append(file);
    }
    return frames;
}

QString imageSequenceDisplayName(const ImageSequence &seq, int frameCount)
{
    const auto split = splitPattern(seq.pattern);
    if (!split)
        return QFileInfo(seq.pattern).fileName();
    const int last = seq.start + std::max(frameCount, 1) - 1;
    const QString range = QStringLiteral("[%1-%2]")
                              .arg(formatNumber(seq.start, split->width), formatNumber(last, split->width));
    const QString full = split->head + range + split->tail;
    return full.mid(full.lastIndexOf(QLatin1Char('/')) + 1);
}

QString imageSequenceFolderName(const ImageSequence &seq)
{
    const auto split = splitPattern(seq.pattern);
    if (!split)
        return QStringLiteral("sequence");
    const QString head = split->head.mid(split->head.lastIndexOf(QLatin1Char('/')) + 1);
    QString name = QFileInfo(head + split->tail).completeBaseName();
    name.replace(QLatin1Char('%'), QLatin1Char('_'));
    while (!name.isEmpty() && QStringLiteral("_-. ").contains(name.back()))
        name.chop(1);
    return name.isEmpty() ? QStringLiteral("sequence") : name;
}

void setImageSequenceFps(ImageSequence &seq, double fps)
{
    if (!(fps > 0)) {
        seq.fpsNum = 0;
        seq.fpsDen = 1;
        return;
    }
    const double rounded = std::round(fps);
    if (std::abs(fps - rounded) < 1e-6) {
        seq.fpsNum = int(rounded);
        seq.fpsDen = 1;
        return;
    }
    for (int base : {24, 30, 48, 60, 120}) {
        if (std::abs(fps - base * 1000.0 / 1001.0) < 0.005) {
            seq.fpsNum = base * 1000;
            seq.fpsDen = 1001;
            return;
        }
    }
    const int num = int(std::lround(fps * 1000.0));
    const int g = std::gcd(num, 1000);
    seq.fpsNum = num / g;
    seq.fpsDen = 1000 / g;
}

QList<DetectedImageSequence> detectImageSequences(const QStringList &absolutePaths, int minFrames)
{
    static const QRegularExpression numbered(QStringLiteral("^(.*?)(\\d+)$"));

    // (dir, prefix, extension) -> candidates, keeping insertion order via Candidate::order.
    QMap<QStringList, QList<Candidate>> buckets;
    for (int i = 0; i < absolutePaths.size(); ++i) {
        const QString &path = absolutePaths[i];
        if (!isImageSuffix(path))
            continue;
        const QFileInfo info(path);
        const QRegularExpressionMatch m = numbered.match(info.completeBaseName());
        if (!m.hasMatch())
            continue;
        Candidate c;
        c.path = path;
        c.dir = info.absolutePath();
        c.prefix = m.captured(1);
        c.digits = m.captured(2);
        c.ext = info.suffix();
        c.order = i;
        if (c.digits.size() > 9)
            continue;
        buckets[{c.dir, c.prefix, c.ext}].append(c);
    }

    QList<QPair<int, DetectedImageSequence>> found;
    for (auto it = buckets.cbegin(); it != buckets.cend(); ++it) {
        const QList<Candidate> &group = it.value();

        // Mixed widths read as an unpadded %d only when no run is zero padded; otherwise each
        // width is its own sequence.
        bool mixedWidths = false, leadingZero = false;
        for (const Candidate &c : group) {
            mixedWidths |= c.digits.size() != group.first().digits.size();
            leadingZero |= c.digits.size() > 1 && c.digits.startsWith(QLatin1Char('0'));
        }

        QMap<int, QList<Candidate>> subgroups; // pattern width (0 = %d) -> candidates
        for (const Candidate &c : group) {
            int width;
            if (mixedWidths && !leadingZero)
                width = 0;
            else
                width = c.digits.size() > 1 ? c.digits.size() : 0;
            subgroups[width].append(c);
        }

        for (const QList<Candidate> &members : std::as_const(subgroups)) {
            const int width = (mixedWidths && !leadingZero) || members.first().digits.size() <= 1
                                  ? 0
                                  : members.first().digits.size();
            int lowest = members.first().digits.toInt();
            int firstOrder = members.first().order;
            for (const Candidate &c : members) {
                lowest = std::min(lowest, c.digits.toInt());
                firstOrder = std::min(firstOrder, c.order);
            }

            const Candidate &ref = members.first();
            ImageSequence seq;
            seq.pattern = escapePercent(ref.dir + QLatin1Char('/') + ref.prefix) + conversionFor(width)
                          + escapePercent(QStringLiteral(".") + ref.ext);
            seq.start = lowest;

            const int frameCount = int(imageSequenceFrames(seq).size());
            if (frameCount < std::max(minFrames, 1))
                continue;

            DetectedImageSequence det;
            det.sequence = seq;
            det.frameCount = frameCount;
            for (const Candidate &c : members) {
                det.consumedPaths.append(c.path);
                if (c.digits.toInt() >= lowest + frameCount)
                    ++det.skippedAfterGap;
            }
            det.displayName = imageSequenceDisplayName(seq, frameCount);
            found.append({firstOrder, det});
        }
    }

    std::stable_sort(found.begin(), found.end(), [](const auto &a, const auto &b) { return a.first < b.first; });
    QList<DetectedImageSequence> out;
    for (const auto &f : std::as_const(found))
        out.append(f.second);
    return out;
}

} // namespace drift
