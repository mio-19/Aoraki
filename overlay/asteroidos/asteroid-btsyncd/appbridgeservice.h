/*
 * Copyright (C) 2026 AsteroidOS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#ifndef APPBRIDGESERVICE_H
#define APPBRIDGESERVICE_H

#include <QObject>
#include <QDBusConnection>
#include <QDBusMessage>
#include "service.h"
#include "characteristic.h"
#include "common.h"

class AppBridgeService;

// TX characteristic: Watch -> Phone notifications
class AppBridgeTxChrc : public Characteristic
{
    Q_OBJECT
    Q_PROPERTY(QByteArray Value READ getValue NOTIFY valueChanged)
public:
    AppBridgeTxChrc(QDBusConnection bus, int index, Service *service);

public slots:
    QByteArray ReadValue(QVariantMap) { return m_value; }
    void StartNotify() {}
    void StopNotify() {}
    void sendPacket(const QByteArray &packet);

signals:
    void valueChanged();

private:
    QByteArray m_value;
    QByteArray getValue() { return m_value; }
    void emitPropertiesChanged();
};

// RX characteristic: Phone -> Watch writes
class AppBridgeRxChrc : public Characteristic
{
    Q_OBJECT
public:
    AppBridgeRxChrc(QDBusConnection bus, int index, AppBridgeService *service);

public slots:
    void WriteValue(QByteArray value, QVariantMap);

private:
    AppBridgeService *m_service;
};

class AppBridgeService : public Service
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.asteroidos.btsyncd.AppBridge")
public:
    explicit AppBridgeService(int index, QDBusConnection bus, QObject *parent = nullptr);

    void handleRxPacket(const QByteArray &packet);

public slots:
    void sendMessage(const QString &appId, const QString &action, const QString &payload);
    void sendBytes(const QString &appId, const QString &action, const QByteArray &payload);

signals:
    void messageReceived(const QString &appId, const QString &action, const QString &payload);

private:
    AppBridgeTxChrc *m_txChrc;
    AppBridgeRxChrc *m_rxChrc;
};

#endif // APPBRIDGESERVICE_H
