#ifndef CHATMODEL_H
#define CHATMODEL_H

#include <QAbstractListModel>
#include <QList>

struct ChatItem {
    QString id;
    QString title;
    QString lastMessage;
    QString time;
    int unreadCount;
    QString avatarColor;
};

class ChatModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString filterQuery READ filterQuery WRITE setFilterQuery NOTIFY filterQueryChanged)

public:
    enum ChatRoles {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        LastMessageRole,
        TimeRole,
        UnreadCountRole,
        AvatarColorRole
    };

    explicit ChatModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filterQuery() const { return m_filterQuery; }
    void setFilterQuery(const QString &query);

    bool hasChat(const QString &id) const;
    void addChat(const QString &id, const QString &title, const QString &lastMessage, const QString &time, int unreadCount, const QString &avatarColor);
    void addOrUpdateChat(const QString &id, const QString &title, const QString &lastMessage, const QString &time, int unreadCount, const QString &avatarColor);
    void updateLastMessage(const QString &chatId, const QString &lastMessage, const QString &time);
    void markAsRead(const QString &chatId);
    void moveChatToTop(const QString &chatId);
    void clear();

    ChatItem getChat(int row) const;
    QList<ChatItem> allChats() const { return m_chats; }

signals:
    void filterQueryChanged();

private:
    void rebuildFilteredChats();

    QList<ChatItem> m_chats;
    QList<ChatItem> m_filteredChats;
    QString m_filterQuery;
};

#endif // CHATMODEL_H
