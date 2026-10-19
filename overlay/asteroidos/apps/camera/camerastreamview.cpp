/*
 * Copyright (C) 2026 AsteroidOS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#include "camerastreamview.h"
#include <QDebug>

CameraStreamView::CameraStreamView(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
    setOpaquePainting(true);

    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &CameraStreamView::onSocketConnected);
    connect(m_socket, &QTcpSocket::disconnected, this, &CameraStreamView::onSocketDisconnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &CameraStreamView::onSocketReadyRead);
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
    connect(m_socket, &QTcpSocket::errorOccurred, this, &CameraStreamView::onSocketError);
#endif

    m_reconnectTimer = new QTimer(this);
    m_reconnectTimer->setInterval(2000);
    connect(m_reconnectTimer, &QTimer::timeout, this, &CameraStreamView::onReconnectTimer);

    m_fpsTimer = new QTimer(this);
    m_fpsTimer->setInterval(1000);
    connect(m_fpsTimer, &QTimer::timeout, this, &CameraStreamView::onFpsTimer);
    m_fpsTimer->start();

    // Connect to AsteroidOS btsyncd AppBridge D-Bus signals for real-time status and preview frames
    QDBusConnection::systemBus().connect(
        QString(),
        "/org/asteroidos/btsyncd/appbridge",
        "org.asteroidos.btsyncd.AppBridge",
        "messageReceived",
        this,
        SLOT(onMessageReceived(QString, QString, QString))
    );

    // Initial query for camera status and stream availability
    QTimer::singleShot(600, this, [this]() {
        sendCommand("status_query");
        sendCommand("start_stream");
    });
}

CameraStreamView::~CameraStreamView()
{
    stopStream();
}

void CameraStreamView::setStreamUrl(const QString &url)
{
    if (m_streamUrl != url) {
        m_streamUrl = url;
        emit streamUrlChanged();
        if (m_active) {
            reconnect();
        }
    }
}

void CameraStreamView::setActive(bool active)
{
    if (m_active != active) {
        m_active = active;
        emit activeChanged();
        if (m_active) {
            startStream();
        } else {
            stopStream();
        }
    }
}

void CameraStreamView::reconnect()
{
    stopStream();
    if (m_active) {
        startStream();
    }
}

void CameraStreamView::startStream()
{
    QString urlStr = m_streamUrl;
    if (urlStr.isEmpty()) {
        urlStr = "http://192.168.44.1:8089/stream.mjpg";
    }

    QUrl url(urlStr);
    QString host = url.host();
    int port = url.port(8089);

    if (host.isEmpty()) {
        host = "192.168.44.1";
    }

    qDebug() << "CameraStreamView: Connecting to stream at" << host << ":" << port;
    m_buffer.clear();
    m_socket->abort();
    m_socket->connectToHost(host, port);
}

void CameraStreamView::stopStream()
{
    m_reconnectTimer->stop();
    if (m_socket && m_socket->isOpen()) {
        m_socket->abort();
    }
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
    m_buffer.clear();
}

void CameraStreamView::onSocketConnected()
{
    qDebug() << "CameraStreamView: Socket connected, sending HTTP GET";
    QString urlStr = m_streamUrl.isEmpty() ? "http://192.168.44.1:8089/stream.mjpg" : m_streamUrl;
    QUrl url(urlStr);
    QString path = url.path().isEmpty() ? "/stream.mjpg" : url.path();

    QByteArray request;
    request.append("GET " + path.toUtf8() + " HTTP/1.1\r\n");
    request.append("Host: " + url.host().toUtf8() + "\r\n");
    request.append("User-Agent: AsteroidOSCamera/1.0\r\n");
    request.append("Connection: close\r\n\r\n");

    m_socket->write(request);
    m_reconnectTimer->stop();
}

void CameraStreamView::onSocketDisconnected()
{
    qDebug() << "CameraStreamView: Socket disconnected";
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
    if (m_active) {
        m_reconnectTimer->start();
    }
}

void CameraStreamView::onSocketError(QAbstractSocket::SocketError error)
{
    qWarning() << "CameraStreamView: Socket error:" << error;
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
    if (m_active && !m_reconnectTimer->isActive()) {
        m_reconnectTimer->start();
    }
}

void CameraStreamView::onReconnectTimer()
{
    if (m_active && (!m_socket || m_socket->state() == QAbstractSocket::UnconnectedState)) {
        startStream();
    }
}

void CameraStreamView::onSocketReadyRead()
{
    m_buffer.append(m_socket->readAll());
    parseBuffer();
}

void CameraStreamView::parseBuffer()
{
    if (m_buffer.size() > 512 * 1024) {
        int lastSoi = -1;
        const char *data = m_buffer.constData();
        int size = m_buffer.size();
        for (int i = size - 2; i >= 0; --i) {
            if ((uint8_t)data[i] == 0xFF && (uint8_t)data[i + 1] == 0xD8) {
                lastSoi = i;
                break;
            }
        }
        if (lastSoi > 0) {
            m_buffer = m_buffer.mid(lastSoi);
        } else {
            m_buffer.clear();
            return;
        }
    }

    while (m_buffer.size() > 4) {
        int soi = -1;
        const char *data = m_buffer.constData();
        int size = m_buffer.size();

        for (int i = 0; i < size - 1; ++i) {
            if ((uint8_t)data[i] == 0xFF && (uint8_t)data[i + 1] == 0xD8) {
                soi = i;
                break;
            }
        }

        if (soi < 0) {
            m_buffer = m_buffer.right(1);
            return;
        }

        int eoi = -1;
        for (int i = soi + 2; i < size - 1; ++i) {
            if ((uint8_t)data[i] == 0xFF && (uint8_t)data[i + 1] == 0xD9) {
                eoi = i + 1;
                break;
            }
        }

        if (eoi < 0) {
            if (soi > 0) {
                m_buffer.remove(0, soi);
            }
            return;
        }

        int jpegLen = eoi - soi + 1;
        QByteArray jpegBytes = m_buffer.mid(soi, jpegLen);
        m_buffer.remove(0, eoi + 1);

        QImage img;
        if (img.loadFromData(jpegBytes, "JPEG")) {
            m_currentFrame = img;
            if (!m_connected) {
                m_connected = true;
                emit connectedChanged();
            }
            m_frameCount++;
            emit frameReceived();
            update();
        }
    }
}

void CameraStreamView::loadFrameBytes(const QByteArray &bytes)
{
    QImage img;
    if (img.loadFromData(bytes, "JPEG")) {
        m_currentFrame = img;
        if (!m_connected) {
            m_connected = true;
            emit connectedChanged();
        }
        m_frameCount++;
        emit frameReceived();
        update();
    }
}

void CameraStreamView::sendCommand(const QString &action, const QString &payload)
{
    // If the live HTTP MJPEG stream is connected, dispatch directly to camera server over network
    if (m_connected && m_socket && m_socket->state() == QAbstractSocket::ConnectedState) {
        QUrl url(m_streamUrl.isEmpty() ? "http://192.168.44.1:8089/stream.mjpg" : m_streamUrl);
        QTcpSocket *cmdSocket = new QTcpSocket(this);
        connect(cmdSocket, &QTcpSocket::connected, [cmdSocket, url, action]() {
            QByteArray req;
            req.append("GET /control?action=" + action.toUtf8() + " HTTP/1.1\r\n");
            req.append("Host: " + url.host().toUtf8() + "\r\n");
            req.append("Connection: close\r\n\r\n");
            cmdSocket->write(req);
        });
        connect(cmdSocket, &QTcpSocket::readyRead, [cmdSocket]() {
            cmdSocket->close();
            cmdSocket->deleteLater();
        });
        connect(cmdSocket, &QAbstractSocket::errorOccurred, [cmdSocket](QAbstractSocket::SocketError) {
            cmdSocket->deleteLater();
        });
        cmdSocket->connectToHost(url.host(), url.port(8089));
        qDebug() << "CameraStreamView: Dispatched direct network control:" << action;
    }

    QDBusInterface appBridge(
        "org.asteroidos.btsyncd",
        "/org/asteroidos/btsyncd/appbridge",
        "org.asteroidos.btsyncd.AppBridge",
        QDBusConnection::systemBus()
    );
    if (appBridge.isValid()) {
        appBridge.call(QDBus::NoBlock, "sendMessage", "org.asteroidos.camera", action, payload);
        qDebug() << "CameraStreamView: Sent command" << action;
    } else {
        qWarning() << "CameraStreamView: AppBridge D-Bus interface is not valid";
    }
}

void CameraStreamView::onMessageReceived(const QString &appId, const QString &action, const QString &payload)
{
    if (appId != "org.asteroidos.camera") return;
    qDebug() << "CameraStreamView: Received message:" << action << "payload:" << payload;

    if (!m_bleConnected) {
        m_bleConnected = true;
        emit bleConnectedChanged();
    }

    if (!payload.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(payload.toUtf8());
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            int port = obj.value("port").toInt(8089);
            QJsonArray ips = obj.value("ips").toArray();
            if (!ips.isEmpty()) {
                QString chosenIp;
                for (const QJsonValue &val : ips) {
                    QString candidate = val.toString();
                    if (candidate.startsWith("192.168.") || candidate.startsWith("172.") || candidate.startsWith("10.")) {
                        chosenIp = candidate;
                        break;
                    }
                }
                if (chosenIp.isEmpty()) {
                    chosenIp = ips.first().toString();
                }
                QString newUrl = QString("http://%1:%2/stream.mjpg").arg(chosenIp).arg(port);
                if (m_streamUrl != newUrl) {
                    setStreamUrl(newUrl);
                }
            }
        }
    }

    if (action == "photo_captured") {
        vibrate(100);
    }

    emit commandReceived(action, payload);
}

void CameraStreamView::paint(QPainter *painter)
{
    QRectF target = boundingRect();

    if (m_currentFrame.isNull()) {
        painter->fillRect(target, QColor(10, 10, 12));
        painter->setPen(QColor(160, 160, 160));
        QFont f = painter->font();
        f.setPointSize(11);
        painter->setFont(f);
        if (m_bleConnected) {
            painter->drawText(target, Qt::AlignCenter, "Shutter Ready (BLE)\n\nLive video feed offline.\nConnect Wi-Fi or BT Tethering\nfor viewfinder.");
        } else {
            painter->drawText(target, Qt::AlignCenter, "Waiting for camera...\n\nTap top badge\nto launch phone camera.");
        }
        return;
    }

    QImage scaled = m_currentFrame.scaled(target.size().toSize(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    qreal x = (target.width() - scaled.width()) / 2.0;
    qreal y = (target.height() - scaled.height()) / 2.0;
    painter->drawImage(QPointF(x, y), scaled);
}

void CameraStreamView::onFpsTimer()
{
    if (m_fps != m_frameCount) {
        m_fps = m_frameCount;
        emit fpsChanged();
    }
    m_frameCount = 0;
}

void CameraStreamView::vibrate(int ms)
{
    Q_UNUSED(ms);
    QDBusInterface ngf(
        "com.nokia.NonGraphicFeedback1.Backend",
        "/com/nokia/NonGraphicFeedback1",
        "com.nokia.NonGraphicFeedback1",
        QDBusConnection::sessionBus()
    );
    if (ngf.isValid()) {
        ngf.call(QDBus::NoBlock, "play", "camera_click", QVariantMap());
    } else {
        QDBusInterface mce(
            "com.nokia.mce",
            "/com/nokia/mce/request",
            "com.nokia.mce.request",
            QDBusConnection::systemBus()
        );
        if (mce.isValid()) {
            mce.call(QDBus::NoBlock, "req_vibrator_pattern_activate", "PatternWebPageTap");
        }
    }
}
