#include "telegramclient.h"
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>

TelegramClient::TelegramClient(QObject *parent)
    : QObject(parent)
    , m_chatModel(new ChatModel(this))
    , m_messageModel(new MessageModel(this))
    , m_accountName("Asteroid User")
    , m_isLoggedIn(false)
    , m_connectionStatus("Offline")
    , m_hapticsEnabled(true)
    , m_lastUpdateId(0)
    , m_network(new QNetworkAccessManager(this))
    , m_pollTimer(new QTimer(this))
    , m_settings("AsteroidOS", "asteroid-telegram")
{
    connect(m_pollTimer, &QTimer::timeout, this, &TelegramClient::onPollTimeout);
    setupDemoData();
    loadSettings();
}

void TelegramClient::setupDemoData()
{
    m_chatModel->clear();
    m_chatHistories.clear();

    m_chatModel->addChat("asteroid_dev", "AsteroidOS Developers", "New smartwatch release build ready", "11:42", 2, "#00A3E0");
    m_chatModel->addChat("wearix_chat", "Wearix Watch Community", "Virtual keyboard RIME works nicely!", "10:15", 1, "#7CA600");
    m_chatModel->addChat("saved_messages", "Saved Messages", "Meeting notes: buy watch bands", "Yesterday", 0, "#FF8C00");
    m_chatModel->addChat("alice_w", "Alice", "See you at 3pm for coffee?", "Yesterday", 0, "#9B59B6");

    // Add initial history for dev chat
    m_chatHistories["asteroid_dev"] = {
        {"1", "Sylvie", "Has anyone tested the latest power profiles?", "11:30", false, true},
        {"2", "Florent", "Yes, battery life improved by 18% in ambient mode.", "11:35", false, true},
        {"3", "Asteroid User", "Awesome! Testing on Fossil Carlyle now.", "11:40", true, true},
        {"4", "Sylvie", "New smartwatch release build ready", "11:42", false, true}
    };

    m_chatHistories["wearix_chat"] = {
        {"1", "Dev", "Added Pinyin, Double Pinyin, and Wubi to virtual keyboard.", "10:10", false, true},
        {"2", "Asteroid User", "Tested luna_pinyin on 400x400 round display.", "10:12", true, true},
        {"3", "Timo", "Virtual keyboard RIME works nicely!", "10:15", false, true}
    };

    m_chatHistories["saved_messages"] = {
        {"1", "Saved Messages", "Meeting notes: buy watch bands", "Yesterday", true, true}
    };

    m_chatHistories["alice_w"] = {
        {"1", "Alice", "Hey, are you free this afternoon?", "Yesterday", false, true},
        {"2", "Alice", "See you at 3pm for coffee?", "Yesterday", false, true}
    };

    // Default select first chat
    selectChat("asteroid_dev", "AsteroidOS Developers");
}

void TelegramClient::loadSettings()
{
    m_botToken = m_settings.value("botToken").toString();
    m_accountName = m_settings.value("accountName", "Asteroid User").toString();
    m_hapticsEnabled = m_settings.value("hapticsEnabled", true).toBool();
    m_isLoggedIn = !m_botToken.isEmpty();

    if (m_isLoggedIn) {
        m_connectionStatus = "Connected";
        m_pollTimer->start(4000);
        fetchUpdates();
    } else {
        m_connectionStatus = "Ready";
    }

    emit isLoggedInChanged();
    emit connectionStatusChanged();
    emit accountNameChanged();
    emit hapticsEnabledChanged();
}

void TelegramClient::saveSettings()
{
    m_settings.setValue("botToken", m_botToken);
    m_settings.setValue("accountName", m_accountName);
    m_settings.setValue("hapticsEnabled", m_hapticsEnabled);
}

void TelegramClient::setHapticsEnabled(bool enabled)
{
    if (m_hapticsEnabled != enabled) {
        m_hapticsEnabled = enabled;
        saveSettings();
        emit hapticsEnabledChanged();
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
        m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered);
    }
    m_chatModel->markAsRead(chatId);
    emit messagesChanged();
}

void TelegramClient::sendMessage(const QString &text)
{
    if (text.trimmed().isEmpty())
        return;

    appendLocalMessage(text);

    if (m_isLoggedIn && !m_botToken.isEmpty() && !m_currentChatId.startsWith("asteroid_") && !m_currentChatId.startsWith("wearix_")) {
        QUrl url(QString("https://api.telegram.org/bot%1/sendMessage").arg(m_botToken));
        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

        QJsonObject json;
        json["chat_id"] = m_currentChatId;
        json["text"] = text;

        m_network->post(request, QJsonDocument(json).toJson());
    }
}

void TelegramClient::sendQuickReply(const QString &text)
{
    sendMessage(text);
}

void TelegramClient::appendLocalMessage(const QString &text)
{
    QString timeStr = QTime::currentTime().toString("hh:mm");
    QString msgId = QString::number(QDateTime::currentMSecsSinceEpoch());

    MessageItem item{msgId, m_accountName, text, timeStr, true, true};
    m_chatHistories[m_currentChatId].append(item);
    m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, item.isOutgoing, item.isDelivered);
    m_chatModel->updateLastMessage(m_currentChatId, text, timeStr);
    emit messagesChanged();
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
                m_connectionStatus = "Connected";
                saveSettings();
                emit isLoggedInChanged();
                emit accountNameChanged();
                emit connectionStatusChanged();
                m_pollTimer->start(4000);
                fetchUpdates();
                return;
            }
        }
        m_connectionStatus = "Login Failed";
        emit connectionStatusChanged();
    });
}

void TelegramClient::loginWithPhone(const QString &phoneNumber)
{
    m_accountName = phoneNumber.trimmed();
    m_isLoggedIn = true;
    m_connectionStatus = "Connected (Phone)";
    saveSettings();
    emit isLoggedInChanged();
    emit accountNameChanged();
    emit connectionStatusChanged();
}

void TelegramClient::logout()
{
    m_isLoggedIn = false;
    m_botToken.clear();
    m_accountName = "Asteroid User";
    m_connectionStatus = "Offline";
    m_pollTimer->stop();
    saveSettings();
    setupDemoData();
    emit isLoggedInChanged();
    emit accountNameChanged();
    emit connectionStatusChanged();
}

void TelegramClient::refresh()
{
    if (m_isLoggedIn) {
        fetchUpdates();
    }
}

void TelegramClient::onPollTimeout()
{
    if (m_isLoggedIn && !m_botToken.isEmpty()) {
        fetchUpdates();
    }
}

void TelegramClient::fetchUpdates()
{
    if (m_botToken.isEmpty())
        return;

    QUrl url(QString("https://api.telegram.org/bot%1/getUpdates").arg(m_botToken));
    QUrlQuery query;
    if (m_lastUpdateId > 0) {
        query.addQueryItem("offset", QString::number(m_lastUpdateId + 1));
    }
    query.addQueryItem("timeout", "5");
    url.setQuery(query);

    QNetworkRequest request(url);
    QNetworkReply *reply = m_network->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        handleNetworkReply(reply);
    });
}

void TelegramClient::handleNetworkReply(QNetworkReply *reply)
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
        if (updateId > m_lastUpdateId) {
            m_lastUpdateId = updateId;
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

            MessageItem item{msgId, sender, text, timeStr, false, true};
            m_chatHistories[chatId].append(item);

            if (m_currentChatId == chatId) {
                m_messageModel->addMessage(item.id, item.senderName, item.text, item.time, false, true);
                emit messagesChanged();
            }

            m_chatModel->updateLastMessage(chatId, text, timeStr);
            emit messageReceived(chatTitle, text);
        }
    }
}
