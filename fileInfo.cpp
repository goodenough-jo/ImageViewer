#include "fileInfo.h"
#include <QMap>
#include <QFileInfo>
#include <QDateTime>
#include <QImageReader>
#include <QImage>

FileInfo::FileInfo(QObject *parent) : QObject(parent) {}

QVariantMap FileInfo::getInfo(const QString &path)
{
    QVariantMap info;
    //QVariantMap 是 Qt 中用于存储键值对数据的容器类，值类型为QVariant（可存储任意Qt支持的类型），键类型为QString（必须为字符串）
    QFileInfo fileInfo(path);
    QImageReader reader(path);
    QImage img(path);

    info["name"] = fileInfo.fileName();
    info["capacity"] = fileInfo.size();
    info["birthtime"] = fileInfo.birthTime();
    info["lastmodified"] = fileInfo.lastModified();
    info["format"] = reader.format();
    info["size"] = reader.size();
    info["quality"] = reader.quality();

    if (!img.isNull()) {
        QMap<QString, QString> exif;
        QStringList keys = img.textKeys();

        qDebug() << "Available EXIF keys:"; //读取存放在图片中的EXIF键值对
        for (const auto &key : keys) {
            exif[key] = img.text(key);
            qDebug() << key << ":" << img.text(key);
        }

        info["model"] = exif.value("Exif.Image.Model", exif.value("Model", ""));
        info["datetime"] = exif.value("Exif.Image.DateTime", exif.value("DateTime", ""));
        QString latitude = exif.value("Exif.GPSInfo.GPSLatitude", exif.value("GPSLatitude", ""));
        QString longitude = exif.value("Exif.GPSInfo.GPSLongitude", exif.value("GPSLongitude", ""));

        if (!latitude.isEmpty() && !longitude.isEmpty()) {
            info["GPS"] = QString("%1, %2").arg(latitude).arg(longitude);
        } else {
            info["GPS"] = "";
        }
    }

    return info;
}
