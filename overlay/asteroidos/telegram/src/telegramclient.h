#ifndef TELEGRAMCLIENT_H
#define TELEGRAMCLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTimer>
#include <QSettings>
#include "chatmodel.h"
#include "messagemodel.h"

class TelegramClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(ChatModel* chats READ chats CONSTANT)
    Q_PROPERTY(MessageModel* messages READ messages NOTIFY messagesChanged)
    Q_PROPERTY(QString currentChatId READ currentChatId NOTIFY currentChatIdChanged)
    Q_PROPERTY(QString currentChatTitle READ currentChatTitle NOTIFY currentChatTitleChanged)
    Q_PROPERTY(QString accountName READ accountName NOTIFY accountNameChanged)
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString connectionStatus READ connectionStatus NOTIFY connectionStatusChanged)
    Q_PROPERTY(bool hapticsEnabled READ hapticsEnabled WRITE setHapticsEnabled NOTIFY hapticsEnabledChanged)

public:
    explicit TelegramClient(QObject *parent = nullptr);

    ChatModel* chats() const { return m_chatModel; }
    MessageModel* messages() const { return m_messageModel; }
    QString currentChatId() const { return m_currentChatId; }
    QString currentChatTitle() const { return m_currentChatTitle; }
    QString accountName() const { return m_accountName; }
    bool isLoggedIn() const { return m_isLoggedIn; }
    QString connectionStatus() const { return m_connectionStatus; }
    bool hapticsEnabled() const { return m_hapticsEnabled; }
    void setHapticsEnabled(bool enabled);

    Q_INVOKABLE void selectChat(const QString &chatId, const QString &title);
    Q_INVOKABLE void sendMessage(const QString &text);
    Q_INVOKABLE void sendQuickReply(const QString &text);
    Q_INVOKABLE void loginWithToken(const QString &token);
    Q_INVOKABLE void loginWithPhone(const QString &phoneNumber);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void refresh();

signals:
    void messagesChanged();
    void currentChatIdChanged();
    void currentChatTitleChanged();
    void accountNameChanged();
    void isLoggedInChanged();
    void connectionStatusChanged();
    void hapticsEnabledChanged();
    void messageReceived(const QString &chatTitle, const QString &text);

private slots:
    void onPollTimeout();
    void handleNetworkReply(QNetworkReply *reply);

private:
    void setupDemoData();
    void loadSettings();
    void saveSettings();
    void fetchUpdates();
    void appendLocalMessage(const QString &text);

    ChatModel *m_chatModel;
    MessageModel *m_messageModel;
    QMap<QString, QList<MessageItem>> m_chatHistories;

    QString m_currentChatId;
    QString m_currentChatTitle;
    QString m_accountName;
    QString m_botToken;
    bool m_isLoggedIn;
    QString m_connectionStatus;
    bool m_hapticsEnabled;
    qint64 m_lastUpdateId;

    QNetworkAccessManager *m_network;
    QTimer *m_pollTimer;
    QSettings m_settings;
};

#endif // TELEGRAMCLIENT_H
