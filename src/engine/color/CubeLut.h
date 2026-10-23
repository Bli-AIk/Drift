#pragma once

#include <QByteArray>
#include <QColor>
#include <QString>

#include <functional>
#include <memory>
#include <vector>

namespace drift {

// A 3D lookup table. rgb holds size^3 triples with red varying fastest, then green, then blue.
// The lattice spans the input range domainMin..domainMax per channel.
struct CubeLut
{
    int size = 0;
    QString title;
    float domainMin[3] = {0.0f, 0.0f, 0.0f};
    float domainMax[3] = {1.0f, 1.0f, 1.0f};
    std::vector<float> rgb;

    bool isValid() const;
};

bool parseCube(const QByteArray &data, CubeLut *out, QString *error = nullptr);
bool loadCubeFile(const QString &path, CubeLut *out, QString *error = nullptr);
CubeLut identityLut(int n);
CubeLut resampledLut(const CubeLut &lut, int n = 33);
// Width n*n, height n. Texel (x = b*n + r, y = g) holds lut(r, g, b), rows top to bottom.
QByteArray bakeTiledRgba8(const CubeLut &lut);
QRgb applyLut(const CubeLut &lut, QRgb px, float amount);

using LutResolver = std::function<QString(const QString &lookId)>;
void setLutResolver(LutResolver resolver);
QString resolveLutPath(const QString &lookId);

// The look's .cube file resampled to 33^3 and baked, cached by path and mtime. Null when the look
// does not resolve or its file does not parse.
// A resolved id is trusted for about a second, or until invalidateLutLookups(), before the catalog
// and the file's mtime are consulted again. outPath, when given, receives the resolved path.
std::shared_ptr<const QByteArray> bakedLutForId(const QString &lookId, QString *outPath = nullptr);
// Forget every resolved id; call when the look catalog changes.
void invalidateLutLookups();
// The same look resampled to 33^3, for CPU previews. Shares bakedLutForId's cache.
std::shared_ptr<const CubeLut> resampledLutForId(const QString &lookId);

} // namespace drift
