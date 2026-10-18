#include "messagemodel.h"

MessageModel::MessageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MessageModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_messages.size();
}

QVariant MessageModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_messages.size())
        return QVariant();

    const MessageItem &item = m_messages.at(index.row());
    switch (role) {
    case IdRole:
        return item.id;
    case SenderRole:
        return item.senderName;
    case TextRole:
        return item.text;
    case TimeRole:
        return item.time;
    case IsOutgoingRole:
        return item.isOutgoing;
    case IsDeliveredRole:
        return item.isDelivered;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> MessageModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "messageId";
    roles[SenderRole] = "senderName";
    roles[TextRole] = "text";
    roles[TimeRole] = "time";
    roles[IsOutgoingRole] = "isOutgoing";
    roles[IsDeliveredRole] = "isDelivered";
    return roles;
}

void MessageModel::addMessage(const QString &id, const QString &sender, const QString &text, const QString &time, bool isOutgoing, bool isDelivered)
{
    beginInsertRows(QModelIndex(), m_messages.size(), m_messages.size());
    m_messages.append({id, sender, text, time, isOutgoing, isDelivered});
    endInsertRows();
}

void MessageModel::clear()
{
    beginResetModel();
    m_messages.clear();
    endResetModel();
}
