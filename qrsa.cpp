#include "qrsa.h"

#include <QStandardPaths>
#include <QDir>

#include <openssl/applink.c>

QRSA::QRSA(QObject *parent)
    : QObject{parent}
{}

void QRSA::generate() const
{
    auto appDataLocations = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    auto appDataLocation = appDataLocations[0];
    QDir(appDataLocation).mkpath(appDataLocation);
    auto pkLocation = appDataLocation + "/rsa_pk.pem";
    auto skLocation = appDataLocation + "/rsa_sk.pem";
    if (QFile(pkLocation).exists() && QFile(skLocation).exists()) {
        return;
    }

    EVP_PKEY* keys = nullptr;
    unsigned int bits = 2048, prime = 3;
    EVP_PKEY_CTX* context = EVP_PKEY_CTX_new_from_name(nullptr, "RSA", nullptr);
    EVP_PKEY_keygen_init(context);
    BIGNUM* big = BN_new();
    BN_set_word(big, prime);
    OSSL_PARAM params[3];
    params[0] = OSSL_PARAM_construct_uint("bits", &bits);
    params[1] = OSSL_PARAM_construct_uint("primes", &prime);
    params[2] = OSSL_PARAM_construct_end();
    EVP_PKEY_CTX_set_params(context, params);
    EVP_PKEY_generate(context, &keys);

    FILE* pkFile = fopen(pkLocation.toLocal8Bit(), "w");
    PEM_write_PUBKEY(pkFile, keys);
    fclose(pkFile);

    FILE* skFile = fopen(skLocation.toLocal8Bit(), "w");
    PEM_write_PrivateKey(skFile, keys, nullptr, nullptr, 0, nullptr, nullptr);
    fclose(skFile);

    BN_free(big);
    EVP_PKEY_CTX_free(context);
    EVP_PKEY_free(keys);
}

QString QRSA::get_pk() const
{
    auto appDataLocations = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    auto appDataLocation = appDataLocations[0];
    QDir(appDataLocation).mkpath(appDataLocation);
    auto pkLocation = appDataLocation + "/rsa_pk.pem";

    QFile pkFile(pkLocation);
    pkFile.open(QIODeviceBase::ReadOnly);
    return QString::fromUtf8(pkFile.readAll());
}

QString QRSA::get_sk() const
{
    auto appDataLocations = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    auto appDataLocation = appDataLocations[0];
    QDir(appDataLocation).mkpath(appDataLocation);
    auto skLocation = appDataLocation + "/rsa_sk.pem";

    QFile skFile(skLocation);
    skFile.open(QIODeviceBase::ReadOnly);
    return QString::fromUtf8(skFile.readAll());
}

QByteArray encrypt_once(const QByteArray &pk, QByteArray plainText)
{
    // qDebug() << "encrypt_once";
    BIO* pkBio = BIO_new_mem_buf(pk.data(), pk.size());
    EVP_PKEY* key = EVP_PKEY_new();
    PEM_read_bio_PUBKEY(pkBio, &key, nullptr, nullptr);

    EVP_PKEY_CTX* context = EVP_PKEY_CTX_new(key, nullptr);
    EVP_PKEY_encrypt_init(context);
    EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_OAEP_PADDING);
    unsigned char* plainData = reinterpret_cast<unsigned char*>(plainText.data());
    std::size_t encryptedDataLength;
    EVP_PKEY_encrypt(context, nullptr, &encryptedDataLength, plainData, plainText.size());
    unsigned char*  cipherText = new unsigned char[encryptedDataLength];
    EVP_PKEY_encrypt(context, cipherText, &encryptedDataLength, plainData, plainText.size());
    auto ret = QByteArray(reinterpret_cast<char*>(cipherText), encryptedDataLength);
    // qDebug() << encryptedDataLength;

    delete[] cipherText;
    EVP_PKEY_CTX_free(context);
    EVP_PKEY_free(key);
    BIO_free_all(pkBio);

    return ret;
}

QString QRSA::encrypt(const QString &pkRef, const QString& plainTextRef) const
{
    QByteArray plainText = plainTextRef.toUtf8();
    QByteArray pk = pkRef.toUtf8();

    // BIO* pkBio = BIO_new_mem_buf(pk.data(), pk.size());
    // EVP_PKEY* key = EVP_PKEY_new();
    // PEM_read_bio_PUBKEY(pkBio, &key, nullptr, nullptr);

    // EVP_PKEY_CTX* context = EVP_PKEY_CTX_new(key, nullptr);
    // EVP_PKEY_encrypt_init(context);
    // EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_OAEP_PADDING);
    // unsigned char* plainData = reinterpret_cast<unsigned char*>(plainText.data());
    // std::size_t encryptedDataLength;
    // EVP_PKEY_encrypt(context, nullptr, &encryptedDataLength, plainData, plainText.size());
    // unsigned char*  cipherText = new unsigned char[encryptedDataLength];
    // EVP_PKEY_encrypt(context, cipherText, &encryptedDataLength, plainData, plainText.size());
    // auto ret = QByteArray(reinterpret_cast<char*>(cipherText), encryptedDataLength);

    // delete[] cipherText;
    // EVP_PKEY_CTX_free(context);
    // EVP_PKEY_free(key);
    // BIO_free_all(pkBio);

    QByteArray ret;
    size_t unit = 128;
    size_t left = 0;
    do {
        ret += encrypt_once(pk, plainText.mid(left, unit));
        left += unit;
    } while (left < plainText.size());

    return QString::fromUtf8(ret.toBase64());
}

QByteArray decrypt_once(const QByteArray &sk, QByteArray cipherText)
{
    // qDebug() << "decrypt_once";
    BIO* skBio = BIO_new_mem_buf(sk.data(), sk.size());
    EVP_PKEY* key = EVP_PKEY_new();
    PEM_read_bio_PrivateKey(skBio, &key, nullptr, nullptr);

    EVP_PKEY_CTX* context = EVP_PKEY_CTX_new(key, nullptr);
    EVP_PKEY_decrypt_init(context);
    EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_OAEP_PADDING);
    unsigned char* cipherTextData = reinterpret_cast<unsigned char*>(cipherText.data());
    std::size_t decryptedDataLength;
    EVP_PKEY_decrypt(context, nullptr, &decryptedDataLength, cipherTextData, cipherText.size());
    unsigned char*  plainText = new unsigned char[decryptedDataLength];
    EVP_PKEY_decrypt(context, plainText, &decryptedDataLength, cipherTextData, cipherText.size());
    auto ret = QByteArray(reinterpret_cast<char*>(plainText), decryptedDataLength);

    delete[] plainText;
    EVP_PKEY_CTX_free(context);
    EVP_PKEY_free(key);
    BIO_free_all(skBio);

    return ret;
}

QString QRSA::decrypt(const QString &skRef, const QString& cipherTextRef) const
{
    QByteArray cipherText = QByteArray::fromBase64(cipherTextRef.toUtf8());
    QByteArray sk = skRef.toUtf8();

    // BIO* skBio = BIO_new_mem_buf(sk.data(), sk.size());
    // EVP_PKEY* key = EVP_PKEY_new();
    // PEM_read_bio_PrivateKey(skBio, &key, nullptr, nullptr);

    // EVP_PKEY_CTX* context = EVP_PKEY_CTX_new(key, nullptr);
    // EVP_PKEY_decrypt_init(context);
    // EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_OAEP_PADDING);
    // unsigned char* cipherTextData = reinterpret_cast<unsigned char*>(cipherText.data());
    // std::size_t decryptedDataLength;
    // EVP_PKEY_decrypt(context, nullptr, &decryptedDataLength, cipherTextData, cipherText.size());
    // unsigned char*  plainText = new unsigned char[decryptedDataLength];
    // EVP_PKEY_decrypt(context, plainText, &decryptedDataLength, cipherTextData, cipherText.size());
    // auto ret = QByteArray(reinterpret_cast<char*>(plainText), decryptedDataLength);

    // delete[] plainText;
    // EVP_PKEY_CTX_free(context);
    // EVP_PKEY_free(key);
    // BIO_free_all(skBio);

    QByteArray ret;
    size_t unit = 256;
    size_t left = 0;
    do {
        ret += decrypt_once(sk, cipherText.mid(left, unit));
        left += unit;
    } while (left < cipherText.size());

    return QString::fromUtf8(ret);
}
