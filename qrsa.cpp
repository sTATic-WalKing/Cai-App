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
    unsigned int bits =2048, prime = 3;
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

QList<QByteArray> QRSA::get() const
{
    auto appDataLocations = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation);
    auto appDataLocation = appDataLocations[0];
    QDir(appDataLocation).mkpath(appDataLocation);
    auto pkLocation = appDataLocation + "/rsa_pk.pem";
    auto skLocation = appDataLocation + "/rsa_sk.pem";

    QList<QByteArray> ret(2);
    QFile pkFile(pkLocation);
    pkFile.open(QIODeviceBase::ReadOnly);
    ret[0] = pkFile.readAll();
    QFile skFile(skLocation);
    skFile.open(QIODeviceBase::ReadOnly);
    ret[1] = skFile.readAll();

    return ret;
}

QByteArray QRSA::encrypt(const QByteArray &pk, const QByteArray& plainTextRef) const
{
    QByteArray plainText = plainTextRef;

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

    delete[] cipherText;
    EVP_PKEY_CTX_free(context);
    EVP_PKEY_free(key);
    BIO_free_all(pkBio);

    return ret;
}

QByteArray QRSA::decrypt(const QByteArray &sk, const QByteArray& cipherTextRef) const
{
    QByteArray cipherText = cipherTextRef;

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
