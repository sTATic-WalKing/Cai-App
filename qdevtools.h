#ifndef QDEVTOOLS_H
#define QDEVTOOLS_H

#include <QObject>

class QQmlApplicationEngine;
class QDevTools : public QObject
{
    Q_OBJECT

    QQmlApplicationEngine * engine;
public:
    explicit QDevTools(QQmlApplicationEngine * e);
    Q_INVOKABLE void screenshot() const;

signals:
};

#endif // QDEVTOOLS_H
