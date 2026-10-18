#include "chatmodel.h"

ChatModel::ChatModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ChatModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_chats.size();
}

QVariant ChatModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_chats.size())
        return QVariant();

    const ChatItem &item = m_chats.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case TitleRole:
        return item.title;
    case LastMessageRole:
        return item.lastMessage;
    case TimeRole:
        return item.time;
    case UnreadCountRole:
        return item.unreadCount;
    case AvatarColorRole:
        return item.avatarColor;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ChatModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "chatId";
    roles[TitleRole] = "title";
    roles[LastMessageRole] = "lastMessage";
    roles[TimeRole] = "time";
    roles[UnreadCountRole] = "unreadCount";
    roles[AvatarColorRole] = "avatarColor";
    return roles;
}

bool ChatModel::hasChat(const QString &id) const
{
    for (const auto &chat : m_chats) {
        if (chat.id == id)
            return true;
    }
    return false;
}

void ChatModel::addChat(const QString &id, const QString &title, const QString &lastMessage, const QString &time, int unreadCount, const QString &avatarColor)
{
    beginInsertRows(QModelIndex(), m_chats.size(), m_chats.size());
    m_chats.append({id, title, lastMessage, time, unreadCount, avatarColor});
    endInsertRows();
}

void ChatModel::addOrUpdateChat(const QString &id, const QString &title, const QString &lastMessage, const QString &time, int unreadCount, const QString &avatarColor)
{
    for (int i = 0; i < m_chats.size(); ++i) {
        if (m_chats[i].id == id) {
            m_chats[i].title = title;
            m_chats[i].lastMessage = lastMessage;
            m_chats[i].time = time;
            if (unreadCount >= 0)
                m_chats[i].unreadCount = unreadCount;
            if (!avatarColor.isEmpty())
                m_chats[i].avatarColor = avatarColor;
            emit dataChanged(index(i), index(i), {TitleRole, LastMessageRole, TimeRole, UnreadCountRole, AvatarColorRole});
            moveChatToTop(id);
            return;
        }
    }
    beginInsertRows(QModelIndex(), 0, 0);
    m_chats.prepend({id, title, lastMessage, time, unreadCount, avatarColor});
    endInsertRows();
}

void ChatModel::moveChatToTop(const QString &chatId)
{
    for (int i = 0; i < m_chats.size(); ++i) {
        if (m_chats[i].id == chatId) {
            if (i > 0) {
                beginMoveRows(QModelIndex(), i, i, QModelIndex(), 0);
                ChatItem item = m_chats.takeAt(i);
                m_chats.prepend(item);
                endMoveRows();
            }
            break;
        }
    }
}

void ChatModel::updateLastMessage(const QString &chatId, const QString &lastMessage, const QString &time)
{
    for (int i = 0; i < m_chats.size(); ++i) {
        if (m_chats[i].id == chatId) {
            m_chats[i].lastMessage = lastMessage;
            m_chats[i].time = time;
            emit dataChanged(index(i), index(i), {LastMessageRole, TimeRole});
            moveChatToTop(chatId);
            break;
        }
    }
}

void ChatModel::markAsRead(const QString &chatId)
{
    for (int i = 0; i < m_chats.size(); ++i) {
        if (m_chats[i].id == chatId) {
            if (m_chats[i].unreadCount > 0) {
                m_chats[i].unreadCount = 0;
                emit dataChanged(index(i), index(i), {UnreadCountRole});
            }
            break;
        }
    }
}

void ChatModel::clear()
{
    beginResetModel();
    m_chats.clear();
    endResetModel();
}

ChatItem ChatModel::getChat(int row) const
{
    if (row >= 0 && row < m_chats.size())
        return m_chats.at(row);
    return ChatItem();
}
