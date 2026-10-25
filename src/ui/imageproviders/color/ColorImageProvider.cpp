#include "ui/imageproviders/color/ColorImageProvider.h"

#include "engine/color/CubeLut.h"

#include <QCache>
#include <QHash>
#include <QMutex>
#include <QMutexLocker>

namespace {

QMutex &storeMutex()
{
    static QMutex mutex;
    return mutex;
}

QHash<QString, QImage> &store()
{
    static QHash<QString, QImage> images;
    return images;
}

// Look thumbnails derived from look/none, keyed by look id and the base frame's cacheKey so a
// new base frame misses without an explicit flush. Bounded so a scrolled-through pack of
// hundreds of looks doesn't keep every one.
QCache<QString, QImage> &lookCache()
{
    static QCache<QString, QImage> cache(256);
    return cache;
}

QImage lookThumbnail(const QString &lookId)
{
    const QImage base = publishedColorImage(QStringLiteral("look/none"));
    if (base.isNull())
        return {};
    const QString key = lookId + QLatin1Char('@') + QString::number(base.cacheKey());
    {
        QMutexLocker lock(&storeMutex());
        if (const QImage *hit = lookCache().object(key))
            return *hit;
    }

    const std::shared_ptr<const drift::CubeLut> lut = drift::resampledLutForId(lookId);
    if (!lut)
        return base;
    QImage graded = base.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < graded.height(); ++y) {
        QRgb *row = reinterpret_cast<QRgb *>(graded.scanLine(y));
        for (int x = 0; x < graded.width(); ++x)
            row[x] = drift::applyLut(*lut, row[x], 1.0f);
    }

    QMutexLocker lock(&storeMutex());
    lookCache().insert(key, new QImage(graded));
    return graded;
}

} // namespace

void publishColorImage(const QString &key, const QImage &img)
{
    QMutexLocker lock(&storeMutex());
    store().insert(key, img);
}

QImage publishedColorImage(const QString &key)
{
    QMutexLocker lock(&storeMutex());
    return store().value(key);
}

ColorImageProvider::ColorImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage ColorImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString key = id.section(QLatin1Char('?'), 0, 0);
    static const QString lookPrefix = QStringLiteral("look/");
    const bool derivedLook = key.startsWith(lookPrefix) && key != QLatin1String("look/none");
    QImage image = derivedLook ? lookThumbnail(key.mid(lookPrefix.size())) : publishedColorImage(key);
    if (image.isNull()) {
        image = QImage(1, 1, QImage::Format_ARGB32_Premultiplied);
        image.fill(Qt::transparent);
    }

    if (requestedSize.isValid() && requestedSize.width() > 0 && requestedSize.height() > 0)
        image = image.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);

    if (size)
        *size = image.size();
    return image;
}
