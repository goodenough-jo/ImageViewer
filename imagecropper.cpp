#include "imagecropper.h"
#include <QDebug>

ImageCropper::ImageCropper(QObject *parent) : QObject(parent) {}

bool ImageCropper::cropImage(const QUrl &sourcePath, const QUrl &savePath, const QRect &cropArea)
{
    // 加载原始图片
    QImage image(sourcePath.toLocalFile());
    if (image.isNull()) {
        qWarning() << "Failed to load image:" << sourcePath;
        return false;
    }

    // 检查裁剪区域是否有效
    if (cropArea.x() < 0 || cropArea.y() < 0 || cropArea.width() <= 0 || cropArea.height() <= 0
        || cropArea.right() > image.width() || cropArea.bottom() > image.height()) {
        qWarning() << "Invalid crop area:" << cropArea;
        return false;
    }

    // 执行裁剪
    QImage cropped = image.copy(cropArea);
    if (cropped.isNull()) {
        qWarning() << "Failed to crop image";
        return false;
    }

    // 保存裁剪后的图片
    if (!cropped.save(savePath.toLocalFile())) {
        qWarning() << "Failed to save cropped image:" << savePath;
        return false;
    }

    return true;
}
