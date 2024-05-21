#ifndef QQRCODE_H
#define QQRCODE_H

#include <QObject>

class QQRCode : public QObject
{
    Q_OBJECT

public:
    explicit QQRCode(QObject *parent = nullptr);
    Q_INVOKABLE QString process(const QUrl& url);

signals:
};

#endif // QQRCODE_H
