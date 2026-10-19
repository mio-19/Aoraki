#include "telegramclient.h"
#include <QDateTime>
#include <QDir>
#include <QStandardPaths>
#include <QUrlQuery>
#include <QLibrary>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QDebug>

TdlibWorker::TdlibWorker(int clientId, td_receive_fn receiveFn, QObject *parent)
    : QThread(parent)
    , m_clientId(clientId)
    , m_receiveFn(receiveFn)
    , m_stopped(false)
{
}

TdlibWorker::~TdlibWorker()
{
    stop();
    wait(2000);
}

void TdlibWorker::stop()
{
    m_stopped = true;
}

void TdlibWorker::run()
{
    while (!m_stopped) {
        if (!m_receiveFn)
            break;
        const char *result = m_receiveFn(0.5);
        if (result && !m_stopped) {
            QString jsonStr = QString::fromUtf8(result);
            emit responseReceived(jsonStr);
        }
    }
}

TelegramClient::TelegramClient(QObject *parent)
    : QObject(parent)
    , m_chatModel(new ChatModel(this))
    , m_messageModel(new MessageModel(this))
    , m_accountName("Telegram User")
    , m_isLoggedIn(false)
    , m_connectionStatus("Connecting...")
    , m_hapticsEnabled(true)
    , m_notificationsEnabled(true)
    , m_loginState("READY")
    , m_settings("AsteroidOS", "asteroid-telegram")
    , m_hasTdlib(false)
    , m_tdlibClientId(0)
    , m_tdlibWorker(nullptr)
    , m_createFn(nullptr)
    , m_sendFn(nullptr)
    , m_receiveFn(nullptr)
    , m_executeFn(nullptr)
{
    initTdlib();
    loadSettings();
}

TelegramClient::~TelegramClient()
{
    if (m_tdlibWorker) {
        m_tdlibWorker->stop();
        m_tdlibWorker->wait(1000);
    }
}

void TelegramClient::initTdlib()
{
#if HAVE_TDLIB
    m_createFn = td_create_client_id;
    m_sendFn = td_send;
    m_receiveFn = td_receive;
    m_executeFn = td_execute;
    m_hasTdlib = true;
#else
    // Try dynamic loading of libtdjson
    QLibrary lib("tdjson");
    if (lib.load()) {
        m_createFn = (td_create_client_id_fn)lib.resolve("td_create_client_id");
        m_sendFn = (td_send_fn)lib.resolve("td_send");
        m_receiveFn = (td_receive_fn)lib.resolve("td_receive");
        m_executeFn = (td_execute_fn)lib.resolve("td_execute");
        if (m_createFn && m_sendFn && m_receiveFn) {
            m_hasTdlib = true;
        }
    }
#endif

    if (m_hasTdlib && m_createFn) {
        m_tdlibClientId = m_createFn();
        m_tdlibWorker = new TdlibWorker(m_tdlibClientId, m_receiveFn, this);
        connect(m_tdlibWorker, &TdlibWorker::responseReceived, this, &TelegramClient::handleTdlibResponse, Qt::QueuedConnection);
        m_tdlibWorker->start();

        // Initial trigger
        QJsonObject getOption;
        getOption["@type"] = "getOption";
        getOption["name"] = "version";
        sendTdlibRequest(getOption);
        qInfo() << "Initialized official TDLib MTProto user client subsystem";
    } else {
        m_connectionStatus = "TDLib Unavailable";
        qWarning() << "TDLib tdjson library could not be loaded";
    }
}

void TelegramClient::sendTdlibRequest(const QJsonObject &request)
{
    if (!m_hasTdlib || m_tdlibClientId == 0 || !m_sendFn)
        return;
    QByteArray bytes = QJsonDocument(request).toJson(QJsonDocument::Compact);
    m_sendFn(m_tdlibClientId, bytes.constData());
}

void TelegramClient::handleTdlibResponse(const QString &jsonStr)
{
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
    if (!doc.isObject())
        return;

    QJsonObject obj = doc.object();
    QString type = obj["@type"].toString();

    if (type == "updateAuthorizationState") {
        QJsonObject state = obj["authorization_state"].toObject();
        processTdlibAuthUpdate(state);
    } else if (type == "updateNewChat") {
        processTdlibNewChat(obj["chat"].toObject());
    } else if (type == "updateChatLastMessage") {
        processTdlibChatLastMessage(obj);
    } else if (type == "updateNewMessage") {
        processTdlibNewMessage(obj["message"].toObject());
    } else if (type == "updateUser") {
        QJsonObject user = obj["user"].toObject();
        qint64 uid = user["id"].toInteger();
        QString name = user["first_name"].toString();
        if (user.contains("last_name") && !user["last_name"].toString().isEmpty()) {
            name += " " + user["last_name"].toString();
        }
        m_tdlibUserNames[uid] = name;
        if (obj["is_current_user"].toBool() || (m_isLoggedIn && m_accountName == "Telegram User")) {
            m_accountName = name;
            saveSettings();
            emit accountNameChanged();
        }
    } else if (type == "user") {
        QString name = obj["first_name"].toString();
        if (obj.contains("last_name") && !obj["last_name"].toString().isEmpty()) {
            name += " " + obj["last_name"].toString();
        }
        if (!name.isEmpty()) {
            m_accountName = name;
            saveSettings();
            emit accountNameChanged();
        }
    } else if (type == "error") {
        m_errorMessage = obj["message"].toString();
        emit errorMessageChanged();
    }
}

void TelegramClient::processTdlibAuthUpdate(const QJsonObject &authState)
{
    QString stateType = authState["@type"].toString();

    if (stateType == "authorizationStateWaitTdlibParameters") {
        QString appDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir().mkpath(appDir + "/tdlib");
        QDir().mkpath(appDir + "/files");

        QJsonObject params;
        params["@type"] = "setTdlibParameters";
        params["use_test_dc"] = false;
        params["database_directory"] = appDir + "/tdlib";
        params["files_directory"] = appDir + "/files";
        params["use_file_database"] = true;
        params["use_chat_info_database"] = true;
        params["use_message_database"] = true;
        params["use_secret_chats"] = false;
        // Official open-source Telegram Desktop API credentials
        params["api_id"] = 2040;
        params["api_hash"] = "b18441a145604ecb11a1b0142f4a377c";
        params["system_language_code"] = "en";
        params["device_model"] = "AsteroidOS Smartwatch";
        params["system_version"] = "NixOS";
        params["application_version"] = "1.0.0";
        params["enable_storage_optimizer"] = true;
        sendTdlibRequest(params);
    } else if (stateType == "authorizationStateWaitPhoneNumber") {
        m_loginState = "WAIT_PHONE";
        m_connectionStatus = "Ready";
        emit loginStateChanged();
        emit connectionStatusChanged();
    } else if (stateType == "authorizationStateWaitCode") {
        m_loginState = "WAIT_CODE";
        m_connectionStatus = "Code Sent";
        emit loginStateChanged();
        emit connectionStatusChanged();
    } else if (stateType == "authorizationStateWaitPassword") {
        m_loginState = "WAIT_PASSWORD";
        m_connectionStatus = "2FA Required";
        emit loginStateChanged();
        emit connectionStatusChanged();
    } else if (stateType == "authorizationStateWaitOtherDeviceConfirmation") {
        m_qrCodeLink = authState["link"].toString();
        m_loginState = "WAIT_QR";
        m_connectionStatus = "Scan QR / Link";
        emit qrCodeLinkChanged();
        emit loginStateChanged();
        emit connectionStatusChanged();
    } else if (stateType == "authorizationStateReady") {
        m_isLoggedIn = true;
        m_loginState = "LOGGED_IN";
        m_connectionStatus = "Connected";
        saveSettings();
        emit isLoggedInChanged();
        emit loginStateChanged();
        emit connectionStatusChanged();

        // Load chats
        QJsonObject loadChats;
        loadChats["@type"] = "loadChats";
        loadChats["limit"] = 30;
        sendTdlibRequest(loadChats);

        // Get current user info
        QJsonObject getMe;
        getMe["@type"] = "getMe";
        sendTdlibRequest(getMe);
    } else if (stateType == "authorizationStateClosed") {
        m_isLoggedIn = false;
        m_loginState = "READY";
        m_connectionStatus = "Not Logged In";
        m_chatModel->clear();
        m_messageModel->clear();
        emit isLoggedInChanged();
        emit loginStateChanged();
        emit connectionStatusChanged();
    }
}

void TelegramClient::processTdlibNewChat(const QJsonObject &chatObj)
{
    QString chatId = QString::number(chatObj["id"].toInteger());
    QString title = chatObj["title"].toString();
    int unreadCount = chatObj["unread_count"].toInt(0);

    QString lastMsgText;
    QString timeStr;
    if (chatObj.contains("last_message")) {
        QJsonObject lastMsg = chatObj["last_message"].toObject();
        QJsonObject content = lastMsg["content"].toObject();
        QString contentType = content["@type"].toString();
        if (contentType == "messageText") {
            lastMsgText = content["text"].toObject()["text"].toString();
        } else if (contentType == "messagePhoto") {
            lastMsgText = "📷 Photo";
        } else if (contentType == "messageVoiceNote") {
            lastMsgText = "🎤 Voice message";
        } else {
            lastMsgText = "Message";
        }

        qint64 dateSec = lastMsg["date"].toInteger();
        QDateTime dt = QDateTime::fromSecsSinceEpoch(dateSec);
        timeStr = dt.time().toString("hh:mm");
    }

    // Deterministic avatar color based on chat id
    uint hash = qHash(chatId);
    QStringList colors = {"#00A3E0", "#7CA600", "#FF8C00", "#9B59B6", "#E74C3C", "#1ABC9C", "#34495E"};
    QString avatarColor = colors.at(hash % colors.size());

    m_chatModel->addOrUpdateChat(chatId, title, lastMsgText, timeStr, unreadCount, avatarColor);
}

void TelegramClient::processTdlibChatLastMessage(const QJsonObject &updateObj)
{
    QString chatId = QString::number(updateObj["chat_id"].toInteger());
    if (!updateObj.contains("last_message"))
        return;

    QJsonObject lastMsg = updateObj["last_message"].toObject();
    QJsonObject content = lastMsg["content"].toObject();
    QString contentType = content["@type"].toString();
    QString text;
    if (contentType == "messageText") {
        text = content["text"].toObject()["text"].toString();
    } else if (contentType == "messagePhoto") {
        text = "📷 Photo";
    } else if (contentType == "messageVoiceNote") {
        text = "🎤 Voice note";
    } else {
        text = "Message";
    }

    qint64 dateSec = lastMsg["date"].toInteger();
    QString timeStr = QDateTime::fromSecsSinceEpoch(dateSec).time().toString("hh:mm");

    m_chatModel->updateLastMessage(chatId, text, timeStr);
}

void TelegramClient::processTdlibNewMessage(const QJsonObject &messageObj)
{
    QString chatId = QString::number(messageObj["chat_id"].toInteger());
    QString msgId = QString::number(messageObj["id"].toInteger());
    bool isOutgoing = messageObj["is_outgoing"].toBool();

    QJsonObject content = messageObj["content"].toObject();
    QString contentType = content["@type"].toString();
    QString text;
    QString msgType = "text";
    QString extraInfo;

    if (contentType == "messageText") {
        text = content["text"].toObject()["text"].toString();
        msgType = "text";
    } else if (contentType == "messagePhoto") {
        text = content["caption"].toObject()["text"].toString();
        if (text.isEmpty()) text = "Photo attachment";
        msgType = "photo";
        extraInfo = "Photo";
    } else if (contentType == "messageVoiceNote") {
        int duration = content["voice_note"].toObject()["duration"].toInt();
        int mins = duration / 60;
        int secs = duration % 60;
        extraInfo = QString("%1:%2").arg(mins).arg(secs, 2, 10, QChar('0'));
        text = content["caption"].toObject()["text"].toString();
        if (text.isEmpty()) text = "Voice note";
        msgType = "voice";
    } else if (contentType == "messageSticker") {
        text = content["sticker"].toObject()["emoji"].toString();
        if (text.isEmpty()) text = "Sticker";
        msgType = "sticker";
        extraInfo = "Sticker";
    } else if (contentType == "messageLocation") {
        text = "Shared location";
        msgType = "location";
        extraInfo = "Pin";
    } else if (contentType == "messageDocument") {
        text = content["document"].toObject()["file_name"].toString();
        if (text.isEmpty()) text = "Document";
        msgType = "document";
        extraInfo = "File";
    } else {
        text = "Message";
    }

    qint64 dateSec = messageObj["date"].toInteger();
    QString timeStr = QDateTime::fromSecsSinceEpoch(dateSec).time().toString("hh:mm");

    qint64 senderId = messageObj["sender_id"].toObject()["user_id"].toInteger();
    QString senderName = m_tdlibUserNames.value(senderId, isOutgoing ? m_accountName : "Contact");

    MessageItem item{msgId, senderName, text, timeStr, isOutgoing, true, msgType, extraInfo};
    m_chatHistories[chatId].append(item);

    if (m_currentChatId == chatId) {
        m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type, item.extraInfo);
        emit messagesChanged();
    }

    m_chatModel->updateLastMessage(chatId, text, timeStr);

    if (!isOutgoing) {
        triggerHaptics();
        showNotification(senderName, text);
        emit messageReceived(senderName, text);
    }
}

void TelegramClient::loadSettings()
{
    m_accountName = m_settings.value("accountName", "Telegram User").toString();
    m_hapticsEnabled = m_settings.value("hapticsEnabled", true).toBool();
    m_notificationsEnabled = m_settings.value("notificationsEnabled", true).toBool();

    m_quickReplies = m_settings.value("quickReplies", QStringList{
        "👍 OK",
        "❤️ Got it!",
        "🏃 On my way!",
        "⏰ In 10 minutes",
        "❌ Can't talk right now",
        "👋 Hi there!",
        "☕ Coffee later?",
        "🎉 Sounds great!",
        "📞 Call you soon",
        "🙏 Thanks!"
    }).toStringList();

    emit isLoggedInChanged();
    emit connectionStatusChanged();
    emit accountNameChanged();
    emit hapticsEnabledChanged();
    emit notificationsEnabledChanged();
    emit quickRepliesChanged();
}

void TelegramClient::saveSettings()
{
    m_settings.setValue("accountName", m_accountName);
    m_settings.setValue("hapticsEnabled", m_hapticsEnabled);
    m_settings.setValue("notificationsEnabled", m_notificationsEnabled);
    m_settings.setValue("quickReplies", m_quickReplies);
}

void TelegramClient::setHapticsEnabled(bool enabled)
{
    if (m_hapticsEnabled != enabled) {
        m_hapticsEnabled = enabled;
        saveSettings();
        emit hapticsEnabledChanged();
    }
}

void TelegramClient::setNotificationsEnabled(bool enabled)
{
    if (m_notificationsEnabled != enabled) {
        m_notificationsEnabled = enabled;
        saveSettings();
        emit notificationsEnabledChanged();
    }
}

void TelegramClient::triggerHaptics()
{
    if (!m_hapticsEnabled)
        return;

    // Trigger haptic vibration via AsteroidOS NonGraphicFeedback service
    QDBusInterface ngf(
        "com.nokia.NonGraphicFeedback1.Backend",
        "/com/nokia/NonGraphicFeedback1",
        "com.nokia.NonGraphicFeedback1",
        QDBusConnection::sessionBus()
    );
    if (ngf.isValid()) {
        ngf.call(QDBus::NoBlock, "play", "chat", QVariantMap());
    }
}

void TelegramClient::showNotification(const QString &title, const QString &text)
{
    if (!m_notificationsEnabled)
        return;

    // Standard freedesktop notifications on AsteroidOS Wayland desktop
    QDBusInterface notify(
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        QDBusConnection::sessionBus()
    );
    if (notify.isValid()) {
        notify.call(QDBus::NoBlock, "Notify",
            "asteroid-telegram",
            0u,
            "asteroid-telegram",
            title,
            text,
            QStringList(),
            QVariantMap(),
            4000
        );
    }
}

void TelegramClient::selectChat(const QString &chatId, const QString &title)
{
    m_currentChatId = chatId;
    m_currentChatTitle = title;
    emit currentChatIdChanged();
    emit currentChatTitleChanged();

    m_messageModel->clear();
    const auto &history = m_chatHistories.value(chatId);
    for (const auto &item : history) {
        m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type, item.extraInfo);
    }
    m_chatModel->markAsRead(chatId);
    emit messagesChanged();

    if (m_hasTdlib && m_isLoggedIn) {
        QJsonObject openChat;
        openChat["@type"] = "openChat";
        openChat["chat_id"] = chatId.toLongLong();
        sendTdlibRequest(openChat);

        QJsonObject viewReq;
        viewReq["@type"] = "viewMessages";
        viewReq["chat_id"] = chatId.toLongLong();
        viewReq["force_read"] = true;
        sendTdlibRequest(viewReq);
    }
}

void TelegramClient::searchChats(const QString &query)
{
    m_chatModel->setFilterQuery(query);
}

void TelegramClient::sendMessage(const QString &text)
{
    QString trimmed = text.trimmed();
    if (trimmed.isEmpty())
        return;

    appendLocalMessage(trimmed, m_accountName, true, "text");

    if (m_hasTdlib && m_isLoggedIn) {
        QJsonObject req;
        req["@type"] = "sendMessage";
        req["chat_id"] = m_currentChatId.toLongLong();
        QJsonObject formattedText;
        formattedText["@type"] = "formattedText";
        formattedText["text"] = trimmed;
        QJsonObject content;
        content["@type"] = "inputMessageText";
        content["text"] = formattedText;
        req["input_message_content"] = content;
        sendTdlibRequest(req);
    }
}

void TelegramClient::sendQuickReply(const QString &text)
{
    sendMessage(text);
}

void TelegramClient::appendLocalMessage(const QString &text, const QString &senderName, bool isOutgoing, const QString &type, const QString &extraInfo)
{
    QString timeStr = QTime::currentTime().toString("hh:mm");
    QString msgId = QString::number(QDateTime::currentMSecsSinceEpoch());
    QString sender = senderName.isEmpty() ? m_accountName : senderName;

    MessageItem item{msgId, sender, text, timeStr, isOutgoing, true, type, extraInfo};
    m_chatHistories[m_currentChatId].append(item);
    m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type, item.extraInfo);
    m_chatModel->updateLastMessage(m_currentChatId, text, timeStr);
    emit messagesChanged();
}

void TelegramClient::requestQrCodeLogin()
{
    if (!m_hasTdlib) {
        m_errorMessage = "TDLib not available on this platform";
        emit errorMessageChanged();
        return;
    }
    m_connectionStatus = "Requesting QR...";
    emit connectionStatusChanged();

    QJsonObject req;
    req["@type"] = "requestQrCodeAuthentication";
    sendTdlibRequest(req);
}

void TelegramClient::sendPhoneNumber(const QString &phoneNumber)
{
    QString trimmed = phoneNumber.trimmed();
    if (trimmed.isEmpty())
        return;

    if (m_hasTdlib) {
        m_connectionStatus = "Sending Phone...";
        emit connectionStatusChanged();

        QJsonObject req;
        req["@type"] = "setAuthenticationPhoneNumber";
        req["phone_number"] = trimmed;
        sendTdlibRequest(req);
    } else {
        m_errorMessage = "TDLib not loaded";
        emit errorMessageChanged();
    }
}

void TelegramClient::sendAuthCode(const QString &code)
{
    QString trimmed = code.trimmed();
    if (trimmed.isEmpty() || !m_hasTdlib)
        return;

    m_connectionStatus = "Checking Code...";
    emit connectionStatusChanged();

    QJsonObject req;
    req["@type"] = "checkAuthenticationCode";
    req["code"] = trimmed;
    sendTdlibRequest(req);
}

void TelegramClient::sendPassword(const QString &password)
{
    if (password.isEmpty() || !m_hasTdlib)
        return;

    m_connectionStatus = "Checking 2FA...";
    emit connectionStatusChanged();

    QJsonObject req;
    req["@type"] = "checkAuthenticationPassword";
    req["password"] = password;
    sendTdlibRequest(req);
}

void TelegramClient::logout()
{
    if (m_hasTdlib) {
        QJsonObject req;
        req["@type"] = "logOut";
        sendTdlibRequest(req);
    }

    m_isLoggedIn = false;
    m_accountName = "Telegram User";
    m_connectionStatus = "Not Logged In";
    m_loginState = "READY";
    clearHistory();
    saveSettings();

    emit isLoggedInChanged();
    emit loginStateChanged();
    emit accountNameChanged();
    emit connectionStatusChanged();
}

void TelegramClient::refresh()
{
    if (m_isLoggedIn && m_hasTdlib) {
        QJsonObject loadChats;
        loadChats["@type"] = "loadChats";
        loadChats["limit"] = 30;
        sendTdlibRequest(loadChats);
    }
}

void TelegramClient::addQuickReply(const QString &text)
{
    QString trimmed = text.trimmed();
    if (!trimmed.isEmpty() && !m_quickReplies.contains(trimmed)) {
        m_quickReplies.append(trimmed);
        saveSettings();
        emit quickRepliesChanged();
    }
}

void TelegramClient::removeQuickReply(int index)
{
    if (index >= 0 && index < m_quickReplies.size()) {
        m_quickReplies.removeAt(index);
        saveSettings();
        emit quickRepliesChanged();
    }
}

void TelegramClient::resetQuickReplies()
{
    m_quickReplies = QStringList{
        "👍 OK",
        "❤️ Got it!",
        "🏃 On my way!",
        "⏰ In 10 minutes",
        "❌ Can't talk right now",
        "👋 Hi there!",
        "☕ Coffee later?",
        "🎉 Sounds great!",
        "📞 Call you soon",
        "🙏 Thanks!"
    };
    saveSettings();
    emit quickRepliesChanged();
}

void TelegramClient::clearHistory()
{
    m_chatHistories.clear();
    m_messageModel->clear();
    m_chatModel->clear();
    emit messagesChanged();
}
