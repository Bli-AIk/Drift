#pragma once

#include <QImage>
#include <QQuickImageProvider>
#include <QString>

// Publishes a rendered image under a key such as "look/none" or "scope/<kind>". Written from any
// thread; served as image://color/<key>, with any ?query stripped so the key can carry a serial.
// image://color/look/<id> is not published: it is look/none with that look applied, computed on
// the requesting (asynchronous Image) thread and cached.
void publishColorImage(const QString &key, const QImage &img);
QImage publishedColorImage(const QString &key);

class ColorImageProvider : public QQuickImageProvider
{
public:
    ColorImageProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
