/*
 * Copyright (C) 2026 AsteroidOS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#ifndef CAMERASTREAMVIEW_H
#define CAMERASTREAMVIEW_H

#include <QQuickPaintedItem>
#include <QImage>
#include <QTcpSocket>
#include <QTimer>
#include <QUrl>
#include <QPainter>
#include <QDBusInterface>
#include <QDBusConnection>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

class CameraStreamView : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString streamUrl READ streamUrl WRITE setStreamUrl NOTIFY streamUrlChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(bool bleConnected READ bleConnected NOTIFY bleConnectedChanged)
    Q_PROPERTY(int fps READ fps NOTIFY fpsChanged)

public:
    explicit CameraStreamView(QQuickItem *parent = nullptr);
    ~CameraStreamView() override;

    QString streamUrl() const { return m_streamUrl; }
    void setStreamUrl(const QString &url);

    bool active() const { return m_active; }
    void setActive(bool active);

    bool connected() const { return m_connected; }
    bool bleConnected() const { return m_bleConnected; }
    int fps() const { return m_fps; }

    void paint(QPainter *painter) override;

public slots:
    void sendCommand(const QString &action, const QString &payload = QString());
    void reconnect();
    void loadFrameBytes(const QByteArray &bytes);
    void vibrate(int ms = 50);

signals:
    void streamUrlChanged();
    void activeChanged();
    void connectedChanged();
    void bleConnectedChanged();
    void fpsChanged();
    void frameReceived();
    void commandReceived(const QString &action, const QString &payload);

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onReconnectTimer();
    void onFpsTimer();
    void onMessageReceived(const QString &appId, const QString &action, const QString &payload);

private:
    void startStream();
    void stopStream();
    void parseBuffer();

    QString m_streamUrl;
    bool m_active = true;
    bool m_connected = false;
    bool m_bleConnected = false;
    int m_fps = 0;
    int m_frameCount = 0;

    QTcpSocket *m_socket = nullptr;
    QTimer *m_reconnectTimer = nullptr;
    QTimer *m_fpsTimer = nullptr;
    QByteArray m_buffer;
    QImage m_currentFrame;
};

#endif // CAMERASTREAMVIEW_H
