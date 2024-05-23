#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include <QQmlContext>

#include "qrsa.h"
#include "qqrcode.h"
#include "qdevtools.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("CQUPT");
    app.setOrganizationDomain("www.cqupt.edu.cn");
    app.setApplicationName("Cai");
    app.setWindowIcon(QIcon(":/icons/app.svg"));

    qmlRegisterType<QRSA>("Cpp", 0, 8, "RSA");
    qmlRegisterType<QQRCode>("Cpp", 0, 8, "QRCode");

    QQmlApplicationEngine engine;

    QDevTools devTools(&engine);
    engine.rootContext()->setContextProperty("devTools", &devTools);

    const QUrl url(QStringLiteral("qrc:/qt/qml/Cai/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
