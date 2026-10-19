/*
 * Copyright (C) 2026 AsteroidOS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

#include "appbridgeservice.h"
#include <QDebug>

AppBridgeTxChrc::AppBridgeTxChrc(QDBusConnection bus, int index, Service *service)
    : Characteristic(bus, index, APP_BRIDGE_TX_UUID,
                     {"read", "notify", "encrypt-authenticated-read", "encrypt-authenticated-notify"},
                     service)
{
}

void AppBridgeTxChrc::sendPacket(const QByteArray &packet)
{
    m_value = packet;
    emit valueChanged();
    emitPropertiesChanged();
    qDebug() << "AppBridge: Sent packet size" << packet.size();
}

void AppBridgeTxChrc::emitPropertiesChanged()
{
    QDBusConnection connection = QDBusConnection::systemBus();
    QDBusMessage message = QDBusMessage::createSignal(getPath().path(),
                                                      "org.freedesktop.DBus.Properties",
                                                      "PropertiesChanged");

    QVariantMap changedProperties;
    changedProperties[QStringLiteral("Value")] = QVariant(m_value);

    QList<QVariant> arguments;
    arguments << QVariant(GATT_CHRC_IFACE) << QVariant(changedProperties) << QVariant(QStringList());
    message.setArguments(arguments);

    if (!connection.send(message)) {
        qDebug() << "AppBridge: Failed to send DBus property notification signal";
    }
}

AppBridgeRxChrc::AppBridgeRxChrc(QDBusConnection bus, int index, AppBridgeService *service)
    : Characteristic(bus, index, APP_BRIDGE_RX_UUID,
                     {"write", "write-without-response", "encrypt-authenticated-write"},
                     service),
      m_service(service)
{
}

void AppBridgeRxChrc::WriteValue(QByteArray value, QVariantMap)
{
    if (m_service) {
        m_service->handleRxPacket(value);
    }
}

AppBridgeService::AppBridgeService(int index, QDBusConnection bus, QObject *parent)
    : Service(bus, index, APP_BRIDGE_UUID, parent)
{
    m_txChrc = new AppBridgeTxChrc(bus, 0, this);
    addCharacteristic(m_txChrc);

    m_rxChrc = new AppBridgeRxChrc(bus, 1, this);
    addCharacteristic(m_rxChrc);

    bus.registerObject("/org/asteroidos/btsyncd/appbridge", this,
                       QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals | QDBusConnection::ExportAllProperties);
}

void AppBridgeService::sendMessage(const QString &appId, const QString &action, const QString &payload)
{
    sendBytes(appId, action, payload.toUtf8());
}

void AppBridgeService::sendBytes(const QString &appId, const QString &action, const QByteArray &payload)
{
    QByteArray appIdBytes = appId.toUtf8();
    QByteArray actionBytes = action.toUtf8();

    if (appIdBytes.size() > 255 || actionBytes.size() > 255) {
        qWarning() << "AppBridge: appId or action too long";
        return;
    }

    QByteArray packet;
    packet.append((char)0xA0);
    packet.append((char)appIdBytes.size());
    packet.append(appIdBytes);
    packet.append((char)actionBytes.size());
    packet.append(actionBytes);
    packet.append(payload);

    if (m_txChrc) {
        m_txChrc->sendPacket(packet);
    }
}

void AppBridgeService::handleRxPacket(const QByteArray &packet)
{
    if (packet.size() < 3) {
        return;
    }

    if ((uint8_t)packet.at(0) != 0xA0) {
        qWarning() << "AppBridge: invalid magic byte" << Qt::hex << (uint8_t)packet.at(0);
        return;
    }

    int offset = 1;
    int appIdLen = (uint8_t)packet.at(offset++);
    if (packet.size() < offset + appIdLen + 1) return;
    QString appId = QString::fromUtf8(packet.mid(offset, appIdLen));
    offset += appIdLen;

    int actionLen = (uint8_t)packet.at(offset++);
    if (packet.size() < offset + actionLen) return;
    QString action = QString::fromUtf8(packet.mid(offset, actionLen));
    offset += actionLen;

    QByteArray payloadBytes = packet.mid(offset);
    QString payload = QString::fromUtf8(payloadBytes);

    qDebug() << "AppBridge: Received message for" << appId << "action:" << action;
    emit messageReceived(appId, action, payload);
}
