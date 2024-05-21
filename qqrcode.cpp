#include "qqrcode.h"
#include <QUrl>
#include <QImage>
#include <QDebug>

#include "ReadBarcode.h"

QQRCode::QQRCode(QObject *parent)
    : QObject{parent}
{}



QString QQRCode::process(const QUrl& url)
{
    QString ret;
#ifdef Q_OS_ANDROID
    QString file = url.toString();
#else
    QString file = url.toLocalFile();
#endif
    QImage qImage(file);
    qImage = qImage.convertToFormat(QImage::Format_Grayscale8);

    auto image = ZXing::ImageView(qImage.constBits(), qImage.width(), qImage.height(), ZXing::ImageFormat::Lum);
    auto options = ZXing::ReaderOptions().setFormats(ZXing::BarcodeFormat::Any);
    auto barcodes = ZXing::ReadBarcodes(image, options);

    if (!barcodes.empty()) {
        ret = QString::fromStdString(barcodes[0].text());
    }

    return ret;
}
