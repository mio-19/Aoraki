#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "zimmanager.h"
#include "zimimageprovider.h"

int main(int argc, char *argv[])
{
    qputenv("QT_QUICK_CONTROLS_STYLE", "Asteroid");
    qputenv("QT_IM_MODULE", "qtvirtualkeyboard");
    qputenv("QT_VIRTUALKEYBOARD_STYLE", "watch");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("asteroid-kiwix"));
    app.setApplicationDisplayName(QStringLiteral("Kiwix"));
    app.setOrganizationName(QStringLiteral("AsteroidOS"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("kiwix")));

    ZimManager zimManager;

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("zim"), new ZimImageProvider(&zimManager));
    engine.rootContext()->setContextProperty(QStringLiteral("zimManager"), &zimManager);

    // Initial scan and load
    if (argc > 1 && QString::fromLocal8Bit(argv[1]).endsWith(QStringLiteral(".zim"))) {
        zimManager.openArchive(QString::fromLocal8Bit(argv[1]));
    } else {
        zimManager.scanArchives();
    }

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
