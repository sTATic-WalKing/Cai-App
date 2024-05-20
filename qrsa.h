#ifndef QRSA_H
#define QRSA_H

#include <QObject>
#include <QFile>

#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>

class QRSA : public QObject
{
    Q_OBJECT

public:
    explicit QRSA(QObject *parent = nullptr);

    Q_INVOKABLE void generate() const;
    Q_INVOKABLE QList<QByteArray> get() const;
    Q_INVOKABLE QByteArray encrypt(const QByteArray& pk, const QByteArray& plainText) const;
    Q_INVOKABLE QByteArray decrypt(const QByteArray& sk, const QByteArray& cipherText) const;

signals:
};

#endif // QRSA_H
