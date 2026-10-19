#include "zimimageprovider.h"
#include "zimmanager.h"

ZimImageProvider::ZimImageProvider(ZimManager *manager)
    : QQuickImageProvider(QQuickImageProvider::Pixmap),
      m_manager(manager)
{
}

QPixmap ZimImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    if (!m_manager) {
        return QPixmap();
    }

    QByteArray data = m_manager->getEntryData(id);
    if (data.isEmpty()) {
        // Try fallback with prefix 'I/' or stripping leading '/'
        QString cleanedId = id;
        if (cleanedId.startsWith(QLatin1String("/"))) {
            cleanedId = cleanedId.mid(1);
        }
        data = m_manager->getEntryData(cleanedId);
        if (data.isEmpty()) {
            data = m_manager->getEntryData(QLatin1String("I/") + cleanedId);
        }
    }

    if (data.isEmpty()) {
        return QPixmap();
    }

    QPixmap pixmap;
    if (!pixmap.loadFromData(data)) {
        return QPixmap();
    }

    if (size) {
        *size = pixmap.size();
    }

    if (requestedSize.width() > 0 && requestedSize.height() > 0) {
        return pixmap.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    return pixmap;
}
