/*
 * AsteroidOS Smartwatch Web Browser
 * Native Qt6 Quick & WebEngine browser tailored for wearable displays
 * Integrated with AsteroidOS Virtual Keyboard (qtvirtualkeyboard & Rime)
 * Upstream architecture: https://asteroidos.org/
 */

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QString>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

int main(int argc, char *argv[])
{
    // Help flag
    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromLocal8Bit(argv[i]);
        if (arg == "-h" || arg == "--help") {
            printf("Usage: asteroid-browser [OPTIONS] [URL]\n");
            printf("AsteroidOS Smartwatch Web Browser powered by QtWebEngine\n\n");
            printf("Options:\n");
            printf("  -h, --help    Show this help message\n");
            return 0;
        }
    }

    // Ensure Asteroid controls style
    qputenv("QT_QUICK_CONTROLS_STYLE", "Asteroid");

    // AsteroidOS Virtual Keyboard environment
    qputenv("QT_IM_MODULE", "qtvirtualkeyboard");
    qputenv("QT_VIRTUALKEYBOARD_STYLE", "watch");

    // Configure Chromium flags for wearable constraints and low memory
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS",
            "--single-process "
            "--in-process-gpu "
            "--renderer-process-limit=1 "
            "--no-sandbox "
            "--disable-dev-shm-usage "
            "--js-flags=--max_old_space_size=64 "
            "--disable-features=Translate,AutofillServerCommunication,OptimizationHints,MediaRouter");

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("asteroid-browser");
    app.setApplicationDisplayName("Browser");
    app.setOrganizationName("AsteroidOS");
    app.setOrganizationDomain("asteroidos.org");
    app.setWindowIcon(QIcon::fromTheme("asteroid-browser", QIcon(":/asteroid-browser.svg")));

    QString shareDir = qEnvironmentVariable("ASTEROID_BROWSER_SHARE", "/usr/share/asteroid-browser");

    QString initialUrl;
    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromLocal8Bit(argv[i]);
        if (!arg.startsWith('-')) {
            initialUrl = arg;
            break;
        }
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("initialUrl", initialUrl);
    engine.rootContext()->setContextProperty("browserShareDir", shareDir);

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
