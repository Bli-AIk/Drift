#pragma once

#include <QString>
#include <QVector3D>

#include <cstdint>
#include <vector>

namespace drift {

// CPU-side Gaussian splat set decoded from SOG (single, bundled or streamed LOD) or binary PLY.
// Coordinates are the file's turned 180 degrees about z (right-handed, y up, as glTF), so they
// place like a model. Colour is SH band 0 only.

struct SplatData
{
    int count = 0;
    std::vector<float> positions; // xyz, count * 3
    std::vector<float> rotations; // unit quaternion w, x, y, z, count * 4
    std::vector<float> scales;    // linear, count * 3
    std::vector<uint8_t> colors;  // RGBA8: SH0 colour and opacity, count * 4

    QVector3D aabbMin{0.f, 0.f, 0.f};
    QVector3D aabbMax{0.f, 0.f, 0.f};
    // Per-axis 2nd..98th percentile of the positions. Outlier splats can stretch the raw box a
    // hundredfold past the content, so placement fits this instead.
    QVector3D fitMin{0.f, 0.f, 0.f};
    QVector3D fitMax{0.f, 0.f, 0.f};

    // Streamed SOG only: the level that was loaded (0 = finest), how many exist, and the splat
    // total of that level across the whole scene (equals count unless a chunk was skipped).
    int lodLevel = -1;
    int lodLevels = 0;
    qint64 totalCount = 0;

    QString error; // non-empty when the load failed; every other field is then empty
};

// How many splats a load aims for: what the renderer can sort and draw per frame.
#if defined(Q_OS_ANDROID) || defined(Q_OS_WASM)
inline constexpr qint64 kSplatBudget = 1'000'000;
#else
inline constexpr qint64 kSplatBudget = 2'500'000;
#endif

// Cheap content sniff: reads at most a PLY header or a zip central directory.
bool isSplatPath(const QString &path);

// splatBudget only steers the level choice of a streamed SOG; other sources load in full.
SplatData loadSplatAsset(const QString &path, qint64 splatBudget);

} // namespace drift
