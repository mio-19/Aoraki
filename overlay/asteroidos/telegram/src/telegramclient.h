#ifndef TELEGRAMCLIENT_H
#define TELEGRAMCLIENT_H

#include <QObject>
#include <QSettings>
#include <QThread>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStringList>
#include <atomic>
#include "chatmodel.h"
#include "messagemodel.h"

#if HAVE_TDLIB
#include <td/telegram/td_json_client.h>
#endif

// Function pointer signatures for TDLib C JSON interface
typedef int (*td_create_client_id_fn)();
typedef void (*td_send_fn)(int, const char *);
typedef const char *(*td_receive_fn)(double);
typedef const char *(*td_execute_fn)(const char *);

class TdlibWorker : public QThread
{
    Q_OBJECT
public:
    TdlibWorker(int clientId, td_receive_fn receiveFn, QObject *parent = nullptr);
    ~TdlibWorker() override;

    void stop();

protected:
    void run() override;

signals:
    void responseReceived(const QString &json);

private:
    int m_clientId;
    td_receive_fn m_receiveFn;
    std::atomic<bool> m_stopped;
};

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
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)
    Q_PROPERTY(QString loginState READ loginState NOTIFY loginStateChanged)
    Q_PROPERTY(QString qrCodeLink READ qrCodeLink NOTIFY qrCodeLinkChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString backendType READ backendType CONSTANT)
    Q_PROPERTY(QStringList quickReplies READ quickReplies NOTIFY quickRepliesChanged)
    Q_PROPERTY(bool hasTdlib READ hasTdlib CONSTANT)

public:
    explicit TelegramClient(QObject *parent = nullptr);
    ~TelegramClient() override;

    ChatModel* chats() const { return m_chatModel; }
    MessageModel* messages() const { return m_messageModel; }
    QString currentChatId() const { return m_currentChatId; }
    QString currentChatTitle() const { return m_currentChatTitle; }
    QString accountName() const { return m_accountName; }
    bool isLoggedIn() const { return m_isLoggedIn; }
    QString connectionStatus() const { return m_connectionStatus; }
    bool hapticsEnabled() const { return m_hapticsEnabled; }
    void setHapticsEnabled(bool enabled);
    bool notificationsEnabled() const { return m_notificationsEnabled; }
    void setNotificationsEnabled(bool enabled);
    QString loginState() const { return m_loginState; }
    QString qrCodeLink() const { return m_qrCodeLink; }
    QString errorMessage() const { return m_errorMessage; }
    QString backendType() const { return QStringLiteral("TDLib MTProto"); }
    QStringList quickReplies() const { return m_quickReplies; }
    bool hasTdlib() const { return m_hasTdlib; }

    Q_INVOKABLE void selectChat(const QString &chatId, const QString &title);
    Q_INVOKABLE void sendMessage(const QString &text);
    Q_INVOKABLE void sendQuickReply(const QString &text);
    Q_INVOKABLE void requestQrCodeLogin();
    Q_INVOKABLE void sendPhoneNumber(const QString &phoneNumber);
    Q_INVOKABLE void sendAuthCode(const QString &code);
    Q_INVOKABLE void sendPassword(const QString &password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void searchChats(const QString &query);
    Q_INVOKABLE void addQuickReply(const QString &text);
    Q_INVOKABLE void removeQuickReply(int index);
    Q_INVOKABLE void resetQuickReplies();
    Q_INVOKABLE void clearHistory();

signals:
    void messagesChanged();
    void currentChatIdChanged();
    void currentChatTitleChanged();
    void accountNameChanged();
    void isLoggedInChanged();
    void connectionStatusChanged();
    void hapticsEnabledChanged();
    void notificationsEnabledChanged();
    void loginStateChanged();
    void qrCodeLinkChanged();
    void errorMessageChanged();
    void quickRepliesChanged();
    void messageReceived(const QString &chatTitle, const QString &text);

private slots:
    void handleTdlibResponse(const QString &jsonStr);

private:
    void loadSettings();
    void saveSettings();
    void appendLocalMessage(const QString &text, const QString &senderName = QString(), bool isOutgoing = true, const QString &type = "text", const QString &extraInfo = QString());
    void triggerHaptics();
    void showNotification(const QString &title, const QString &text);

    // TDLib subsystem
    void initTdlib();
    void sendTdlibRequest(const QJsonObject &request);
    void processTdlibAuthUpdate(const QJsonObject &authState);
    void processTdlibNewChat(const QJsonObject &chatObj);
    void processTdlibNewMessage(const QJsonObject &messageObj);
    void processTdlibChatLastMessage(const QJsonObject &updateObj);

    ChatModel *m_chatModel;
    MessageModel *m_messageModel;
    QMap<QString, QList<MessageItem>> m_chatHistories;

    QString m_currentChatId;
    QString m_currentChatTitle;
    QString m_accountName;
    bool m_isLoggedIn;
    QString m_connectionStatus;
    bool m_hapticsEnabled;
    bool m_notificationsEnabled;
    QString m_loginState;
    QString m_qrCodeLink;
    QString m_errorMessage;
    QStringList m_quickReplies;

    QSettings m_settings;

    // TDLib variables
    bool m_hasTdlib;
    int m_tdlibClientId;
    TdlibWorker *m_tdlibWorker;
    td_create_client_id_fn m_createFn;
    td_send_fn m_sendFn;
    td_receive_fn m_receiveFn;
    td_execute_fn m_executeFn;
    QMap<qint64, QString> m_tdlibUserNames;
};

#endif // TELEGRAMCLIENT_H
