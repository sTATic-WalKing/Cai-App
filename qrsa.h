#ifndef QRSA_H
#define QRSA_H

#include <QObject>
#include <QFile>

class QRSA : public QObject
{
    Q_OBJECT

public:
    explicit QRSA(QObject *parent = nullptr);

    Q_INVOKABLE void generate() const;
    Q_INVOKABLE QString get_pk() const;
    Q_INVOKABLE QString get_sk() const;
    Q_INVOKABLE QString encrypt(const QString& pk, const QString& plainText) const;
    Q_INVOKABLE QString decrypt(const QString& sk, const QString& cipherText) const;

signals:
};

#endif // QRSA_H
