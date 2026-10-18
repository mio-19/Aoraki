#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "telegramclient.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Asteroid");

    QGuiApplication app(argc, argv);
    app.setApplicationName("asteroid-telegram");
    app.setApplicationDisplayName("Telegram");
    app.setOrganizationName("AsteroidOS");
    app.setOrganizationDomain("asteroidos.org");
    app.setWindowIcon(QIcon::fromTheme("asteroid-telegram", QIcon(":/asteroid-telegram.svg")));

    TelegramClient client;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("telegramClient", &client);
    engine.rootContext()->setContextProperty("chatModel", client.chats());
    engine.rootContext()->setContextProperty("messageModel", client.messages());

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
