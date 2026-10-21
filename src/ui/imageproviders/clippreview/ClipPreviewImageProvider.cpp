#include "ui/imageproviders/clippreview/ClipPreviewImageProvider.h"

#include "playback/preview/ClipPreviewImageStore.h"

ClipPreviewImageProvider::ClipPreviewImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage ClipPreviewImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id); // only "frame" is served; the ?rev= query exists to defeat QML's URL cache

    QImage image = ClipPreviewImageStore::frame();
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
