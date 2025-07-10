#pragma once
#include <QObject>
#include <QImage>
#include <QUrl>
#include <QRect>

class ImageCropper : public QObject
{
    Q_OBJECT
public:
    explicit ImageCropper(QObject *parent = nullptr);

    Q_INVOKABLE bool cropImage(const QUrl &sourcePath, const QUrl &savePath, const QRect &cropArea);
};
