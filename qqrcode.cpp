#include "qqrcode.h"
#include <QUrl>
#include <QImage>
#include <QDebug>

#ifdef Q_OS_IOS
#include "libs/ios/framework/bridge.h"
#else
#include "DynamsoftBarcodeReader.h"
#endif

QQRCode::QQRCode(QObject *parent)
    : QObject{parent}
{
    reader = DBR_CreateInstance();
    char errorMessage[512];
    DBR_InitLicense("t0068lQAAAADzp3lUi3CvNLBL6yS3rJpLqGAYypsUspgkNL5pUbKc6GtcPjaicJ5LZFYc+Yi7SoySPHosyJzJutUQ3XxlVfI=", errorMessage, 512);
    DBR_InitRuntimeSettingsWithString(reader, "{\"Version\":\"3.0\", \"ImageParameter\":{\"Name\":\"IP1\", \"BarcodeFormatIds\":[\"BF_ALL\"], \"ExpectedBarcodesCount\":10}}", CM_OVERWRITE, errorMessage, 512);
}

QQRCode::~QQRCode()
{
    DBR_DestroyInstance(reader);
}

QString QQRCode::process(const QUrl& url)
{
    QString ret;
    QImage image(url.toLocalFile());
    image = image.convertToFormat(QImage::Format_RGBA8888);

    int width = image.width();
    int height = image.height();
    int bytesPerLine = image.bytesPerLine();
    const uchar *pixelData = image.constBits();

    DBR_DecodeBuffer(reader, pixelData, width, height, bytesPerLine, IPF_ABGR_8888, "");

    TextResultArray *handler = NULL;
    DBR_GetAllTextResults(reader, &handler);
    TextResult **results = handler->results;

    // for (int index = 0; index < count; index++)
    // {
    //     //        LocalizationResult* localizationResult = results[index]->localizationResult;
    //     ret += "Index: " + QString::number(index)  + "\n";
    //     ret += "Barcode format: " + QLatin1String(results[index]->barcodeFormatString) + "\n";
    //     ret += "Barcode value: " + QLatin1String(results[index]->barcodeText) + "\n";
    //     //                            out += "Bounding box: (" + QString::number(localizationResult->x1) + ", " + QString::number(localizationResult->y1) + ") "
    //     //                            + "(" + QString::number(localizationResult->x2) + ", " + QString::number(localizationResult->y2) + ") "
    //     //                            + "(" + QString::number(localizationResult->x3) + ", " + QString::number(localizationResult->y3) + ") "
    //     //                            + "(" + QString::number(localizationResult->x4) + ", " + QString::number(localizationResult->y4) + ")\n";
    //     ret += "----------------------------------------------------------------------------------------\n";
    // }
    if (handler->resultsCount) {
        ret = QString::fromUtf8(QByteArray(results[0]->barcodeText));
    }
    DBR_FreeTextResults(&handler);

    return ret;
}
