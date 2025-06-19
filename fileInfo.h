#pragma once
#include <QObject>
#include <QMap>
#include <QVariant>
#include <QString>

class FileInfo : public QObject
{
    Q_OBJECT
public:
    explicit FileInfo(QObject *parent = nullptr);
    Q_INVOKABLE QVariantMap getInfo(const QString &path);
};
