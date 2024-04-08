#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("CQUPT");
    app.setOrganizationDomain("www.cqupt.edu.cn");
    app.setApplicationName("Cai");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/qt/qml/Cai/Main.qml"));

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
