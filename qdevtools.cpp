#include "qdevtools.h"

#include <QQmlApplicationEngine>
#include <QQuickWindow>

QDevTools::QDevTools(QQmlApplicationEngine * e)
    : engine(e)
{}

void QDevTools::screenshot() const
{
    auto objects = engine->rootObjects();
    QQuickWindow* window = qobject_cast<QQuickWindow*>(objects.first());
    if (window) {
        QImage image = window->grabWindow();
        qDebug() << image;
        image.save("D:/.projects/Cai/Screenshot.png");
    }
}
