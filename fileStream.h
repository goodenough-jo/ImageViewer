#pragma once
#include <QFile>
#include <QObject>

class FileStream : public QObject
{
    Q_OBJECT

public:
    explicit FileStream(QObject *parent = nullptr);

    Q_INVOKABLE bool moveToTrash(const QString &filePath);
    Q_INVOKABLE QString lastError() const;

signals:
    void fileRemoved(const QString &path);

private:
    QString m_lastError;
};
