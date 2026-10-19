#ifndef ZIMIMAGEPROVIDER_H
#define ZIMIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QPixmap>

class ZimManager;

class ZimImageProvider : public QQuickImageProvider
{
public:
    explicit ZimImageProvider(ZimManager *manager);

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    ZimManager *m_manager;
};

#endif // ZIMIMAGEPROVIDER_H
