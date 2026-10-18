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
    , m_accountName("Asteroid User")
    , m_isLoggedIn(false)
    , m_connectionStatus("Ready")
    , m_hapticsEnabled(true)
    , m_notificationsEnabled(true)
    , m_loginState("READY")
    , m_backendType("Demo")
    , m_lastBotUpdateId(0)
    , m_network(new QNetworkAccessManager(this))
    , m_pollTimer(new QTimer(this))
    , m_settings("AsteroidOS", "asteroid-telegram")
    , m_hasTdlib(false)
    , m_tdlibClientId(0)
    , m_tdlibWorker(nullptr)
    , m_createFn(nullptr)
    , m_sendFn(nullptr)
    , m_receiveFn(nullptr)
    , m_executeFn(nullptr)
{
    connect(m_pollTimer, &QTimer::timeout, this, &TelegramClient::onPollTimeout);

    initTdlib();
    loadSettings();
    if (!m_isLoggedIn) {
        setupDemoData();
    }
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
        qInfo() << "Initialized official TDLib MTProto client subsystem";
    } else {
        qInfo() << "TDLib tdjson not present, running HTTP Bot API & local cache mode";
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
        if (obj["is_current_user"].toBool() || (m_isLoggedIn && m_accountName.isEmpty())) {
            m_accountName = name;
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
        m_backendType = "TDLib MTProto";
        m_connectionStatus = "Connected";
        saveSettings();
        emit isLoggedInChanged();
        emit loginStateChanged();
        emit backendTypeChanged();
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
        m_connectionStatus = "Offline";
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

    if (contentType == "messageText") {
        text = content["text"].toObject()["text"].toString();
        msgType = "text";
    } else if (contentType == "messagePhoto") {
        text = content["caption"].toObject()["text"].toString();
        if (text.isEmpty()) text = "Photo";
        msgType = "photo";
    } else if (contentType == "messageVoiceNote") {
        int duration = content["voice_note"].toObject()["duration"].toInt();
        text = QString("Voice note (%1s)").arg(duration);
        msgType = "voice";
    } else {
        text = "Message";
    }

    qint64 dateSec = messageObj["date"].toInteger();
    QString timeStr = QDateTime::fromSecsSinceEpoch(dateSec).time().toString("hh:mm");

    qint64 senderId = messageObj["sender_id"].toObject()["user_id"].toInteger();
    QString senderName = m_tdlibUserNames.value(senderId, isOutgoing ? m_accountName : "Contact");

    MessageItem item{msgId, senderName, text, timeStr, isOutgoing, true, msgType};
    m_chatHistories[chatId].append(item);

    if (m_currentChatId == chatId) {
        m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type);
        emit messagesChanged();
    }

    m_chatModel->updateLastMessage(chatId, text, timeStr);

    if (!isOutgoing) {
        triggerHaptics();
        showNotification(senderName, text);
        emit messageReceived(senderName, text);
    }
}

void TelegramClient::setupDemoData()
{
    m_chatModel->clear();
    m_chatHistories.clear();

    m_chatModel->addChat("asteroid_dev", "AsteroidOS Developers", "New smartwatch release build ready", "11:42", 2, "#00A3E0");
    m_chatModel->addChat("wearix_chat", "Wearix Watch Community", "Virtual keyboard RIME works nicely!", "10:15", 1, "#7CA600");
    m_chatModel->addChat("saved_messages", "Saved Messages", "Meeting notes: buy watch bands", "Yesterday", 0, "#FF8C00");
    m_chatModel->addChat("alice_w", "Alice", "See you at 3pm for coffee?", "Yesterday", 0, "#9B59B6");

    m_chatHistories["asteroid_dev"] = {
        {"1", "Sylvie", "Has anyone tested the latest power profiles?", "11:30", false, true, "text"},
        {"2", "Florent", "Yes, battery life improved by 18% in ambient mode.", "11:35", false, true, "text"},
        {"3", "Asteroid User", "Awesome! Testing on Fossil Carlyle now.", "11:40", true, true, "text"},
        {"4", "Sylvie", "New smartwatch release build ready", "11:42", false, true, "text"}
    };

    m_chatHistories["wearix_chat"] = {
        {"1", "Dev", "Added Pinyin, Double Pinyin, and Wubi to virtual keyboard.", "10:10", false, true, "text"},
        {"2", "Asteroid User", "Tested luna_pinyin on 400x400 round display.", "10:12", true, true, "text"},
        {"3", "Timo", "Virtual keyboard RIME works nicely!", "10:15", false, true, "text"}
    };

    m_chatHistories["saved_messages"] = {
        {"1", "Saved Messages", "Meeting notes: buy watch bands", "Yesterday", true, true, "text"}
    };

    m_chatHistories["alice_w"] = {
        {"1", "Alice", "Hey, are you free this afternoon?", "Yesterday", false, true, "text"},
        {"2", "Alice", "See you at 3pm for coffee?", "Yesterday", false, true, "text"}
    };

    selectChat("asteroid_dev", "AsteroidOS Developers");
}

void TelegramClient::loadSettings()
{
    m_botToken = m_settings.value("botToken").toString();
    m_accountName = m_settings.value("accountName", "Asteroid User").toString();
    m_hapticsEnabled = m_settings.value("hapticsEnabled", true).toBool();
    m_notificationsEnabled = m_settings.value("notificationsEnabled", true).toBool();
    m_backendType = m_settings.value("backendType", "Demo").toString();

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

    if (!m_botToken.isEmpty()) {
        m_isLoggedIn = true;
        m_backendType = "Bot API";
        m_connectionStatus = "Connected";
        m_pollTimer->start(4000);
        fetchBotUpdates();
    }

    emit isLoggedInChanged();
    emit connectionStatusChanged();
    emit accountNameChanged();
    emit hapticsEnabledChanged();
    emit notificationsEnabledChanged();
    emit backendTypeChanged();
    emit quickRepliesChanged();
}

void TelegramClient::saveSettings()
{
    m_settings.setValue("botToken", m_botToken);
    m_settings.setValue("accountName", m_accountName);
    m_settings.setValue("hapticsEnabled", m_hapticsEnabled);
    m_settings.setValue("notificationsEnabled", m_notificationsEnabled);
    m_settings.setValue("backendType", m_backendType);
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
        m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type);
    }
    m_chatModel->markAsRead(chatId);
    emit messagesChanged();

    if (m_hasTdlib && m_isLoggedIn) {
        QJsonObject openChat;
        openChat["@type"] = "openChat";
        openChat["chat_id"] = chatId.toLongLong();
        sendTdlibRequest(openChat);
    }
}

void TelegramClient::sendMessage(const QString &text)
{
    QString trimmed = text.trimmed();
    if (trimmed.isEmpty())
        return;

    appendLocalMessage(trimmed, m_accountName, true, "text");

    if (m_hasTdlib && m_backendType == "TDLib MTProto") {
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
    } else if (!m_botToken.isEmpty() && !m_currentChatId.startsWith("asteroid_") && !m_currentChatId.startsWith("wearix_")) {
        sendBotMessage(m_currentChatId, trimmed);
    }
}

void TelegramClient::sendQuickReply(const QString &text)
{
    sendMessage(text);
}

void TelegramClient::appendLocalMessage(const QString &text, const QString &senderName, bool isOutgoing, const QString &type)
{
    QString timeStr = QTime::currentTime().toString("hh:mm");
    QString msgId = QString::number(QDateTime::currentMSecsSinceEpoch());
    QString sender = senderName.isEmpty() ? m_accountName : senderName;

    MessageItem item{msgId, sender, text, timeStr, isOutgoing, true, type};
    m_chatHistories[m_currentChatId].append(item);
    m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered, item.type);
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
        // Fallback simulated phone connection
        m_accountName = trimmed;
        m_isLoggedIn = true;
        m_backendType = "Local";
        m_connectionStatus = "Connected (Phone)";
        saveSettings();
        emit isLoggedInChanged();
        emit accountNameChanged();
        emit connectionStatusChanged();
        emit backendTypeChanged();
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

void TelegramClient::loginWithToken(const QString &token)
{
    QString trimmed = token.trimmed();
    if (trimmed.isEmpty())
        return;

    m_connectionStatus = "Connecting...";
    emit connectionStatusChanged();

    QUrl url(QString("https://api.telegram.org/bot%1/getMe").arg(trimmed));
    QNetworkRequest request(url);
    QNetworkReply *reply = m_network->get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, trimmed]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject() && doc.object()["ok"].toBool()) {
                QJsonObject user = doc.object()["result"].toObject();
                m_accountName = user["first_name"].toString();
                m_botToken = trimmed;
                m_isLoggedIn = true;
                m_backendType = "Bot API";
                m_connectionStatus = "Connected";
                saveSettings();
                emit isLoggedInChanged();
                emit accountNameChanged();
                emit connectionStatusChanged();
                emit backendTypeChanged();
                m_pollTimer->start(4000);
                fetchBotUpdates();
                return;
            }
        }
        m_connectionStatus = "Login Failed";
        m_errorMessage = "Invalid Bot Token or Connection Error";
        emit errorMessageChanged();
        emit connectionStatusChanged();
    });
}

void TelegramClient::logout()
{
    if (m_hasTdlib && m_backendType == "TDLib MTProto") {
        QJsonObject req;
        req["@type"] = "logOut";
        sendTdlibRequest(req);
    }

    m_isLoggedIn = false;
    m_botToken.clear();
    m_accountName = "Asteroid User";
    m_connectionStatus = "Ready";
    m_loginState = "READY";
    m_backendType = "Demo";
    m_pollTimer->stop();
    saveSettings();
    setupDemoData();

    emit isLoggedInChanged();
    emit loginStateChanged();
    emit accountNameChanged();
    emit connectionStatusChanged();
    emit backendTypeChanged();
}

void TelegramClient::refresh()
{
    if (m_isLoggedIn) {
        if (m_backendType == "TDLib MTProto") {
            QJsonObject loadChats;
            loadChats["@type"] = "loadChats";
            loadChats["limit"] = 30;
            sendTdlibRequest(loadChats);
        } else {
            fetchBotUpdates();
        }
    }
}

void TelegramClient::onPollTimeout()
{
    if (m_isLoggedIn && !m_botToken.isEmpty()) {
        fetchBotUpdates();
    }
}

void TelegramClient::fetchBotUpdates()
{
    if (m_botToken.isEmpty())
        return;

    QUrl url(QString("https://api.telegram.org/bot%1/getUpdates").arg(m_botToken));
    QUrlQuery query;
    if (m_lastBotUpdateId > 0) {
        query.addQueryItem("offset", QString::number(m_lastBotUpdateId + 1));
    }
    query.addQueryItem("timeout", "5");
    url.setQuery(query);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_network->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleBotNetworkReply(reply);
    });
}

void TelegramClient::handleBotNetworkReply(QNetworkReply *reply)
{
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject() || !doc.object()["ok"].toBool()) {
        return;
    }

    QJsonArray updates = doc.object()["result"].toArray();
    for (const auto &val : updates) {
        QJsonObject update = val.toObject();
        qint64 updateId = update["update_id"].toInteger();
        if (updateId > m_lastBotUpdateId) {
            m_lastBotUpdateId = updateId;
        }

        if (update.contains("message")) {
            QJsonObject msg = update["message"].toObject();
            QString text = msg["text"].toString();
            QJsonObject chat = msg["chat"].toObject();
            QString chatId = QString::number(chat["id"].toInteger());
            QString chatTitle = chat.contains("title") ? chat["title"].toString() : chat["first_name"].toString();
            QJsonObject from = msg["from"].toObject();
            QString sender = from["first_name"].toString();
            QString timeStr = QTime::currentTime().toString("hh:mm");
            QString msgId = QString::number(msg["message_id"].toInteger());

            uint hash = qHash(chatId);
            QStringList colors = {"#00A3E0", "#7CA600", "#FF8C00", "#9B59B6", "#E74C3C", "#1ABC9C", "#34495E"};
            QString avatarColor = colors.at(hash % colors.size());

            m_chatModel->addOrUpdateChat(chatId, chatTitle, text, timeStr, 1, avatarColor);

            MessageItem item{msgId, sender, text, timeStr, false, true, "text"};
            m_chatHistories[chatId].append(item);

            if (m_currentChatId == chatId) {
                m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, false, true, "text");
                emit messagesChanged();
            }

            triggerHaptics();
            showNotification(chatTitle, text);
            emit messageReceived(chatTitle, text);
        }
    }
}

void TelegramClient::sendBotMessage(const QString &chatId, const QString &text)
{
    QUrl url(QString("https://api.telegram.org/bot%1/sendMessage").arg(m_botToken));
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["chat_id"] = chatId;
    json["text"] = text;

    m_network->post(request, QJsonDocument(json).toJson());
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
