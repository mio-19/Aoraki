#ifndef MESSAGEMODEL_H
#define MESSAGEMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QList>

struct MessageItem {
    QString id;
    QString senderName;
    QString text;
    QString time;
    bool isOutgoing;
    bool isDelivered;
    QString type; // "text", "voice", "photo", "location", "sticker", "document"
    QString extraInfo;
};

class MessageModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum MessageRoles {
        IdRole = Qt::UserRole + 1,
        SenderRole,
        TextRole,
        TimeRole,
        IsOutgoingRole,
        IsDeliveredRole,
        TypeRole,
        ExtraInfoRole
    };

    explicit MessageModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addMessage(const QString &id, const QString &sender, const QString &text, const QString &time, bool isOutgoing, bool isDelivered = true, const QString &type = "text", const QString &extraInfo = QString());
    void updateDelivered(const QString &id, bool isDelivered);
    void clear();

    QList<MessageItem> allMessages() const { return m_messages; }

private:
    QList<MessageItem> m_messages;
};

#endif // MESSAGEMODEL_H
