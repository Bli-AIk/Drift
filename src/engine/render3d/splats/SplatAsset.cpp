#include "engine/render3d/splats/SplatAsset.h"

#include "core/base/ZipArchive.h"

#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QImage>
#include <QImageReader>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>
#include <map>
#include <memory>

namespace drift {
namespace {

constexpr float kShC0 = 0.28209479177387814f;

bool isMetaName(const QString &name)
{
    return name == QLatin1String("meta.json") || name == QLatin1String("lod-meta.json");
}

// A directory or a zip, addressed by root-relative paths.
class Source
{
public:
    bool open(const QString &path, QString *meta, QString *error)
    {
        const QFileInfo info(path);
        if (info.isDir()) {
            m_dir = info.absoluteFilePath();
            return findDirMeta(meta, error);
        }
        if (isMetaName(info.fileName())) {
            m_dir = info.absolutePath();
            *meta = info.fileName();
            return true;
        }
        m_file.setFileName(path);
        if (!m_file.open(QIODevice::ReadOnly)) {
            *error = QStringLiteral("Cannot open %1").arg(path);
            return false;
        }
        QString zipErr;
        const QList<zip::Entry> entries = zip::readEntries(m_file, &zipErr);
        if (entries.isEmpty()) {
            *error = zipErr.isEmpty() ? QStringLiteral("Empty or invalid archive") : zipErr;
            return false;
        }
        QString best;
        int bestDepth = std::numeric_limits<int>::max();
        bool bestLod = false;
        for (const zip::Entry &e : entries) {
            if (e.isDir)
                continue;
            m_entries.insert(e.path, e);
            const QString name = e.path.section(QLatin1Char('/'), -1);
            if (!isMetaName(name))
                continue;
            const int depth = e.path.count(QLatin1Char('/'));
            const bool lod = name == QLatin1String("lod-meta.json");
            if (depth < bestDepth || (depth == bestDepth && lod && !bestLod)) {
                best = e.path;
                bestDepth = depth;
                bestLod = lod;
            }
        }
        if (best.isEmpty()) {
            *error = QStringLiteral("No meta.json or lod-meta.json in archive");
            return false;
        }
        *meta = best;
        return true;
    }

    bool read(const QString &rel, QByteArray *out, QString *error)
    {
        if (m_file.isOpen()) {
            const auto it = m_entries.constFind(rel);
            if (it == m_entries.constEnd() || !zip::extractEntry(m_file, it.value(), *out)) {
                *error = QStringLiteral("Cannot read %1 from archive").arg(rel);
                return false;
            }
            return true;
        }
        QFile f(QDir(m_dir).filePath(rel));
        if (!f.open(QIODevice::ReadOnly)) {
            *error = QStringLiteral("Cannot open %1").arg(f.fileName());
            return false;
        }
        *out = f.readAll();
        return true;
    }

private:
    bool findDirMeta(QString *meta, QString *error)
    {
        for (const char *name : {"lod-meta.json", "meta.json"}) {
            if (QFileInfo::exists(QDir(m_dir).filePath(QLatin1String(name)))) {
                *meta = QLatin1String(name);
                return true;
            }
        }
        *error = QStringLiteral("No meta.json or lod-meta.json in %1").arg(m_dir);
        return false;
    }

    QString m_dir;
    QFile m_file;
    QHash<QString, zip::Entry> m_entries;
};

QString joinRel(const QString &baseFile, const QString &rel)
{
    const QString dir = baseFile.contains(QLatin1Char('/')) ? baseFile.section(QLatin1Char('/'), 0, -2)
                                                           : QString();
    return QDir::cleanPath(dir.isEmpty() ? rel : dir + QLatin1Char('/') + rel);
}

bool parseJson(const QByteArray &bytes, QJsonObject *out, QString *error)
{
    QJsonParseError pe;
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &pe);
    if (!doc.isObject()) {
        *error = QStringLiteral("Invalid JSON: %1").arg(pe.errorString());
        return false;
    }
    *out = doc.object();
    return true;
}

// Raw bytes, never premultiplied: quats carry a mode in alpha, so any colour conversion would
// corrupt them. A premultiplied result from the plugin is rejected rather than converted.
bool decodeWebp(const QByteArray &bytes, QImage *out, QString *error)
{
    QBuffer buf;
    buf.setData(bytes);
    buf.open(QIODevice::ReadOnly);
    QImageReader reader(&buf, "webp");
    QImage img = reader.read();
    if (img.isNull()) {
        *error = QStringLiteral("WebP decode failed: %1").arg(reader.errorString());
        return false;
    }
    switch (img.format()) {
    case QImage::Format_RGBA8888:
        break;
    case QImage::Format_ARGB32:
    case QImage::Format_RGB32:
    case QImage::Format_RGB888:
        img = img.convertToFormat(QImage::Format_RGBA8888);
        break;
    default:
        *error = QStringLiteral("WebP decoded to an unsupported format (%1)").arg(int(img.format()));
        return false;
    }
    *out = std::move(img);
    return true;
}

bool loadImage(Source &src, const QString &rel, QImage *out, QString *error)
{
    QByteArray bytes;
    return src.read(rel, &bytes, error) && decodeWebp(bytes, out, error);
}

inline const uint8_t *px(const QImage &img, qint64 i)
{
    return img.constScanLine(int(i / img.width())) + (i % img.width()) * 4;
}

bool readCodebook(const QJsonObject &o, std::vector<float> *out, QString *error)
{
    const QJsonArray a = o.value(QLatin1String("codebook")).toArray();
    if (a.size() != 256) {
        *error = QStringLiteral("SOG codebook must have 256 entries");
        return false;
    }
    out->resize(256);
    for (int i = 0; i < 256; ++i)
        (*out)[size_t(i)] = float(a[i].toDouble());
    return true;
}

bool readFiles(const QJsonObject &o, int n, QStringList *out, QString *error)
{
    const QJsonArray a = o.value(QLatin1String("files")).toArray();
    if (a.size() != n) {
        *error = QStringLiteral("SOG meta.json is missing image files");
        return false;
    }
    for (const QJsonValue &v : a)
        out->append(v.toString());
    return true;
}

using Range = std::pair<int, int>; // offset, count

// Splat files keep their capture's camera axes, +y pointing down; PlayCanvas and SuperSplat turn
// them 180 degrees about z on load, and so does this, into the +y up space model clips use.
void finishLoad(SplatData &d)
{
    if (d.count == 0)
        return;
    for (int i = 0; i < d.count; ++i) {
        float *p = &d.positions[size_t(i) * 3];
        p[0] = -p[0];
        p[1] = -p[1];
        float *q = &d.rotations[size_t(i) * 4];
        const float w = q[0], x = q[1], y = q[2], z = q[3];
        q[0] = -z;
        q[1] = -y;
        q[2] = x;
        q[3] = w;
    }
    QVector3D lo(std::numeric_limits<float>::max(), std::numeric_limits<float>::max(),
                 std::numeric_limits<float>::max());
    QVector3D hi = -lo;
    for (int i = 0; i < d.count; ++i) {
        const float *p = &d.positions[size_t(i) * 3];
        lo = QVector3D(std::min(lo.x(), p[0]), std::min(lo.y(), p[1]), std::min(lo.z(), p[2]));
        hi = QVector3D(std::max(hi.x(), p[0]), std::max(hi.y(), p[1]), std::max(hi.z(), p[2]));
    }
    d.aabbMin = lo;
    d.aabbMax = hi;

    const size_t stride = std::max<size_t>(1, size_t(d.count) / 200000);
    std::vector<float> axis;
    float fit[2][3];
    for (int k = 0; k < 3; ++k) {
        axis.clear();
        for (size_t i = 0; i < size_t(d.count); i += stride)
            axis.push_back(d.positions[i * 3 + size_t(k)]);
        const size_t lowIdx = axis.size() * 2 / 100;
        const size_t highIdx = std::min(axis.size() - 1, axis.size() * 98 / 100);
        std::nth_element(axis.begin(), axis.begin() + ptrdiff_t(lowIdx), axis.end());
        fit[0][k] = axis[lowIdx];
        std::nth_element(axis.begin(), axis.begin() + ptrdiff_t(highIdx), axis.end());
        fit[1][k] = axis[highIdx];
    }
    d.fitMin = QVector3D(fit[0][0], fit[0][1], fit[0][2]);
    d.fitMax = QVector3D(fit[1][0], fit[1][1], fit[1][2]);
}

// Decodes one SOG v2 set. `ranges` empty means every splat; otherwise just those pixel ranges,
// concatenated in order.
bool decodeSog(Source &src, const QString &metaPath, const std::vector<Range> &ranges, SplatData *out,
               QString *error)
{
    QByteArray metaBytes;
    QJsonObject meta;
    if (!src.read(metaPath, &metaBytes, error) || !parseJson(metaBytes, &meta, error))
        return false;
    if (meta.value(QLatin1String("version")).toInt() != 2) {
        *error = QStringLiteral("Unsupported SOG version %1 (need 2)")
                     .arg(meta.value(QLatin1String("version")).toInt());
        return false;
    }
    const qint64 total = qint64(meta.value(QLatin1String("count")).toDouble());
    if (total <= 0) {
        *error = QStringLiteral("SOG has no splats");
        return false;
    }

    const QJsonObject means = meta.value(QLatin1String("means")).toObject();
    const QJsonObject scalesO = meta.value(QLatin1String("scales")).toObject();
    const QJsonObject quatsO = meta.value(QLatin1String("quats")).toObject();
    const QJsonObject sh0O = meta.value(QLatin1String("sh0")).toObject();
    QStringList meansFiles, scalesFiles, quatsFiles, sh0Files;
    std::vector<float> scaleBook, sh0Book;
    if (!readFiles(means, 2, &meansFiles, error) || !readFiles(scalesO, 1, &scalesFiles, error)
        || !readFiles(quatsO, 1, &quatsFiles, error) || !readFiles(sh0O, 1, &sh0Files, error)
        || !readCodebook(scalesO, &scaleBook, error) || !readCodebook(sh0O, &sh0Book, error))
        return false;
    const QJsonArray mins = means.value(QLatin1String("mins")).toArray();
    const QJsonArray maxs = means.value(QLatin1String("maxs")).toArray();
    if (mins.size() != 3 || maxs.size() != 3) {
        *error = QStringLiteral("SOG means is missing mins/maxs");
        return false;
    }
    double lo[3], span[3];
    for (int c = 0; c < 3; ++c) {
        lo[c] = mins[c].toDouble();
        span[c] = maxs[c].toDouble() - lo[c];
    }

    QImage meansL, meansU, quats, scales, sh0;
    if (!loadImage(src, joinRel(metaPath, meansFiles[0]), &meansL, error)
        || !loadImage(src, joinRel(metaPath, meansFiles[1]), &meansU, error)
        || !loadImage(src, joinRel(metaPath, quatsFiles[0]), &quats, error)
        || !loadImage(src, joinRel(metaPath, scalesFiles[0]), &scales, error)
        || !loadImage(src, joinRel(metaPath, sh0Files[0]), &sh0, error))
        return false;
    for (const QImage *img : {&meansL, &meansU, &quats, &scales, &sh0}) {
        if (qint64(img->width()) * img->height() < total) {
            *error = QStringLiteral("SOG image is smaller than the splat count");
            return false;
        }
    }
    if (meansL.size() != meansU.size()) {
        *error = QStringLiteral("SOG means images differ in size");
        return false;
    }

    std::vector<Range> all;
    const std::vector<Range> *use = &ranges;
    if (ranges.empty()) {
        all.push_back({0, int(total)});
        use = &all;
    }
    qint64 n = 0;
    for (const Range &r : *use) {
        if (r.first < 0 || r.second < 0 || qint64(r.first) + r.second > total) {
            *error = QStringLiteral("SOG range outside the chunk");
            return false;
        }
        n += r.second;
    }

    const size_t base = size_t(out->count);
    out->positions.resize((base + size_t(n)) * 3);
    out->rotations.resize((base + size_t(n)) * 4);
    out->scales.resize((base + size_t(n)) * 3);
    out->colors.resize((base + size_t(n)) * 4);

    constexpr float kInvSqrt2 = 0.70710678118654752f;
    size_t o = base;
    for (const Range &r : *use) {
        for (qint64 i = r.first; i < qint64(r.first) + r.second; ++i, ++o) {
            const uint8_t *l = px(meansL, i);
            const uint8_t *u = px(meansU, i);
            for (int c = 0; c < 3; ++c) {
                const double v = lo[c] + span[c] * double((u[c] << 8) | l[c]) / 65535.0;
                out->positions[o * 3 + size_t(c)] = float(std::copysign(std::expm1(std::fabs(v)), v));
            }

            const uint8_t *qp = px(quats, i);
            const int mode = int(qp[3]) - 252;
            float *rot = &out->rotations[o * 4];
            if (mode < 0 || mode > 3) {
                rot[0] = 1.f;
                rot[1] = rot[2] = rot[3] = 0.f;
            } else {
                float kept[3];
                float sumSq = 0.f;
                for (int c = 0; c < 3; ++c) {
                    kept[c] = (float(qp[c]) / 255.f - 0.5f) * 2.f * kInvSqrt2;
                    sumSq += kept[c] * kept[c];
                }
                int k = 0;
                for (int c = 0; c < 4; ++c)
                    rot[c] = c == mode ? std::sqrt(std::max(0.f, 1.f - sumSq)) : kept[k++];
            }

            const uint8_t *sp = px(scales, i);
            for (int c = 0; c < 3; ++c)
                out->scales[o * 3 + size_t(c)] = std::exp(scaleBook[sp[c]]);

            const uint8_t *cp = px(sh0, i);
            for (int c = 0; c < 3; ++c) {
                const float col = 0.5f + sh0Book[cp[c]] * kShC0;
                out->colors[o * 4 + size_t(c)] = uint8_t(std::lround(std::clamp(col, 0.f, 1.f) * 255.f));
            }
            out->colors[o * 4 + 3] = cp[3];
        }
    }
    out->count = int(base + size_t(n));
    return true;
}

SplatData loadSog(Source &src, const QString &metaPath, qint64 budget)
{
    SplatData d;
    QString err;
    QByteArray bytes;
    QJsonObject meta;
    if (!src.read(metaPath, &bytes, &err) || !parseJson(bytes, &meta, &err)) {
        d.error = err;
        return d;
    }

    if (metaPath.section(QLatin1Char('/'), -1) != QLatin1String("lod-meta.json")) {
        if (decodeSog(src, metaPath, {}, &d, &err)) {
            d.totalCount = d.count;
            finishLoad(d);
        } else {
            d = SplatData();
            d.error = err;
        }
        return d;
    }

    if (meta.value(QLatin1String("version")).toInt() != 1) {
        d.error = QStringLiteral("Unsupported lod-meta version %1 (need 1)")
                      .arg(meta.value(QLatin1String("version")).toInt());
        return d;
    }
    const QJsonArray counts = meta.value(QLatin1String("counts")).toArray();
    const QJsonArray filenames = meta.value(QLatin1String("filenames")).toArray();
    const int levels = counts.size();
    if (levels == 0 || filenames.isEmpty()) {
        d.error = QStringLiteral("lod-meta.json has no levels");
        return d;
    }
    int level = levels - 1;
    for (int i = 0; i < levels; ++i) {
        if (budget <= 0 || qint64(counts[i].toDouble()) <= budget) {
            level = i;
            break;
        }
    }

    // File index → ranges, in tree order; std::map keeps the output order deterministic.
    std::map<int, std::vector<Range>> byFile;
    std::vector<QJsonObject> stack{meta.value(QLatin1String("tree")).toObject()};
    while (!stack.empty()) {
        const QJsonObject node = stack.back();
        stack.pop_back();
        const QJsonObject lods = node.value(QLatin1String("lods")).toObject();
        if (!lods.isEmpty()) {
            // A leaf that lacks this level falls back to the nearest coarser one.
            for (int l = level; l < levels; ++l) {
                const QJsonValue v = lods.value(QString::number(l));
                if (!v.isObject())
                    continue;
                const QJsonObject lo = v.toObject();
                byFile[lo.value(QLatin1String("file")).toInt()].push_back(
                    {lo.value(QLatin1String("offset")).toInt(), lo.value(QLatin1String("count")).toInt()});
                break;
            }
            continue;
        }
        const QJsonArray kids = node.value(QLatin1String("children")).toArray();
        for (int i = kids.size() - 1; i >= 0; --i)
            stack.push_back(kids[i].toObject());
    }

    for (const auto &[file, ranges] : byFile) {
        if (file < 0 || file >= filenames.size()) {
            d = SplatData();
            d.error = QStringLiteral("lod-meta.json references file index %1").arg(file);
            return d;
        }
        if (!decodeSog(src, joinRel(metaPath, filenames[file].toString()), ranges, &d, &err)) {
            d = SplatData();
            d.error = err;
            return d;
        }
    }
    d.lodLevel = level;
    d.lodLevels = levels;
    d.totalCount = qint64(counts[level].toDouble());
    finishLoad(d);
    return d;
}

// --- PLY ---------------------------------------------------------------------------------------

struct PlyProp
{
    QString name;
    int size = 0;
    char kind = 'f'; // f float, i signed, u unsigned
    int offset = 0;
};

struct PlyHeader
{
    bool binaryLE = false;
    qint64 vertexCount = 0;
    std::vector<PlyProp> props;
    int stride = 0;
    qint64 dataOffset = 0;
    QString error;
};

bool plyType(const QString &t, int *size, char *kind)
{
    static const QHash<QString, std::pair<int, char>> types{
        {"char", {1, 'i'}},   {"int8", {1, 'i'}},   {"uchar", {1, 'u'}},  {"uint8", {1, 'u'}},
        {"short", {2, 'i'}},  {"int16", {2, 'i'}},  {"ushort", {2, 'u'}}, {"uint16", {2, 'u'}},
        {"int", {4, 'i'}},    {"int32", {4, 'i'}},  {"uint", {4, 'u'}},   {"uint32", {4, 'u'}},
        {"float", {4, 'f'}},  {"float32", {4, 'f'}}, {"double", {8, 'f'}}, {"float64", {8, 'f'}},
    };
    const auto it = types.constFind(t);
    if (it == types.constEnd())
        return false;
    *size = it->first;
    *kind = it->second;
    return true;
}

PlyHeader readPlyHeader(QFile &f)
{
    PlyHeader h;
    constexpr qint64 kMaxHeader = 1 << 20;
    f.seek(0);
    const QByteArray head = f.read(kMaxHeader);
    const int end = head.indexOf("end_header");
    if (!head.startsWith("ply") || end < 0) {
        h.error = QStringLiteral("Not a PLY file");
        return h;
    }
    int nl = head.indexOf('\n', end);
    if (nl < 0) {
        h.error = QStringLiteral("Truncated PLY header");
        return h;
    }
    h.dataOffset = nl + 1;

    bool inVertex = false, sawVertex = false, otherBefore = false;
    for (const QByteArray &raw : head.left(end).split('\n')) {
        const QStringList w = QString::fromLatin1(raw).trimmed().split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (w.isEmpty())
            continue;
        if (w[0] == QLatin1String("format")) {
            if (w.size() < 2 || w[1] != QLatin1String("binary_little_endian")) {
                h.error = QStringLiteral("Only binary_little_endian PLY is supported (got %1)")
                              .arg(w.value(1));
                return h;
            }
            h.binaryLE = true;
        } else if (w[0] == QLatin1String("element")) {
            inVertex = w.value(1) == QLatin1String("vertex");
            if (inVertex) {
                sawVertex = true;
                h.vertexCount = w.value(2).toLongLong();
            } else if (!sawVertex) {
                otherBefore = true;
            }
        } else if (w[0] == QLatin1String("property") && inVertex) {
            PlyProp p;
            if (w.size() != 3 || !plyType(w[1], &p.size, &p.kind)) {
                h.error = QStringLiteral("Unsupported PLY vertex property: %1").arg(w.join(QLatin1Char(' ')));
                return h;
            }
            p.name = w[2];
            p.offset = h.stride;
            h.stride += p.size;
            h.props.push_back(p);
        }
    }
    if (!h.binaryLE)
        h.error = QStringLiteral("PLY has no format line");
    else if (!sawVertex || h.vertexCount <= 0)
        h.error = QStringLiteral("PLY has no vertex element");
    else if (otherBefore)
        h.error = QStringLiteral("PLY vertex element must come first");
    return h;
}

float plyValue(const char *p, const PlyProp &prop)
{
    switch (prop.kind) {
    case 'f':
        if (prop.size == 4) {
            float v;
            std::memcpy(&v, p, 4);
            return v;
        } else {
            double v;
            std::memcpy(&v, p, 8);
            return float(v);
        }
    case 'i':
        switch (prop.size) {
        case 1: return float(*reinterpret_cast<const int8_t *>(p));
        case 2: { int16_t v; std::memcpy(&v, p, 2); return float(v); }
        default: { int32_t v; std::memcpy(&v, p, 4); return float(v); }
        }
    default:
        switch (prop.size) {
        case 1: return float(*reinterpret_cast<const uint8_t *>(p));
        case 2: { uint16_t v; std::memcpy(&v, p, 2); return float(v); }
        default: { uint32_t v; std::memcpy(&v, p, 4); return float(v); }
        }
    }
}

SplatData loadPly(const QString &path)
{
    SplatData d;
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        d.error = QStringLiteral("Cannot open %1").arg(path);
        return d;
    }
    const PlyHeader h = readPlyHeader(f);
    if (!h.error.isEmpty()) {
        d.error = h.error;
        return d;
    }

    static const char *const kNames[] = {"x", "y", "z", "f_dc_0", "f_dc_1", "f_dc_2", "opacity",
                                         "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3"};
    const PlyProp *idx[14];
    for (int i = 0; i < 14; ++i) {
        idx[i] = nullptr;
        for (const PlyProp &p : h.props) {
            if (p.name == QLatin1String(kNames[i])) {
                idx[i] = &p;
                break;
            }
        }
        if (!idx[i]) {
            d.error = QStringLiteral("PLY is not a 3DGS splat file (missing property %1)")
                          .arg(QLatin1String(kNames[i]));
            return d;
        }
    }
    if (h.vertexCount > std::numeric_limits<int>::max() / 4
        || f.size() - h.dataOffset < h.vertexCount * h.stride) {
        d.error = QStringLiteral("PLY vertex data is truncated");
        return d;
    }

    const size_t n = size_t(h.vertexCount);
    d.positions.resize(n * 3);
    d.rotations.resize(n * 4);
    d.scales.resize(n * 3);
    d.colors.resize(n * 4);

    constexpr qint64 kBatch = 65536;
    QByteArray buf;
    f.seek(h.dataOffset);
    for (qint64 first = 0; first < h.vertexCount; first += kBatch) {
        const qint64 m = std::min(kBatch, h.vertexCount - first);
        buf = f.read(m * h.stride);
        if (buf.size() != m * h.stride) {
            d = SplatData();
            d.error = QStringLiteral("PLY vertex data is truncated");
            return d;
        }
        for (qint64 k = 0; k < m; ++k) {
            const char *v = buf.constData() + k * h.stride;
            float a[14];
            for (int i = 0; i < 14; ++i)
                a[i] = plyValue(v + idx[i]->offset, *idx[i]);
            const size_t o = size_t(first + k);
            std::memcpy(&d.positions[o * 3], a, 3 * sizeof(float));
            for (int c = 0; c < 3; ++c) {
                const float col = 0.5f + a[3 + c] * kShC0;
                d.colors[o * 4 + size_t(c)] = uint8_t(std::lround(std::clamp(col, 0.f, 1.f) * 255.f));
                d.scales[o * 3 + size_t(c)] = std::exp(a[7 + c]);
            }
            d.colors[o * 4 + 3] = uint8_t(std::lround(255.f / (1.f + std::exp(-a[6]))));
            float len = std::sqrt(a[10] * a[10] + a[11] * a[11] + a[12] * a[12] + a[13] * a[13]);
            if (len < 1e-12f) {
                d.rotations[o * 4] = 1.f;
                d.rotations[o * 4 + 1] = d.rotations[o * 4 + 2] = d.rotations[o * 4 + 3] = 0.f;
            } else {
                for (int c = 0; c < 4; ++c)
                    d.rotations[o * 4 + size_t(c)] = a[10 + c] / len;
            }
        }
    }
    d.count = int(n);
    d.totalCount = d.count;
    finishLoad(d);
    return d;
}

bool plyLooksLikeSplat(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return false;
    const QByteArray head = f.read(64 * 1024);
    const int end = head.indexOf("end_header");
    if (!head.startsWith("ply") || end < 0)
        return false;
    const QByteArray hdr = head.left(end);
    return hdr.contains("f_dc_0") && hdr.contains("rot_0");
}

bool zipHoldsSog(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly) || !zip::looksLikeZip(f.read(4)))
        return false;
    for (const zip::Entry &e : zip::readEntries(f, nullptr)) {
        if (!e.isDir && isMetaName(e.path))
            return true;
    }
    return false;
}

} // namespace

bool isSplatPath(const QString &path)
{
    const QFileInfo info(path);
    if (info.isDir())
        return QFileInfo::exists(QDir(path).filePath(QStringLiteral("meta.json")))
               || QFileInfo::exists(QDir(path).filePath(QStringLiteral("lod-meta.json")));
    if (isMetaName(info.fileName()))
        return true;
    const QString ext = info.suffix().toLower();
    if (ext == QLatin1String("sog"))
        return true;
    if (ext == QLatin1String("ply"))
        return plyLooksLikeSplat(path);
    if (ext == QLatin1String("zip"))
        return zipHoldsSog(path);
    return false;
}

SplatData loadSplatAsset(const QString &path, qint64 splatBudget)
{
    if (QFileInfo(path).suffix().compare(QLatin1String("ply"), Qt::CaseInsensitive) == 0
        && !QFileInfo(path).isDir())
        return loadPly(path);

    Source src;
    QString meta, err;
    if (!src.open(path, &meta, &err)) {
        SplatData d;
        d.error = err;
        return d;
    }
    return loadSog(src, meta, splatBudget);
}

} // namespace drift
