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

    Q_INVOKABLE bool renameFile(const QString &oldPath, const QString &newname);

signals:
    void fileRemoved(const QString &path);
    void fileRenamed(const QString &oldpath, const QString &newPath);

private:
    QString m_lastError;
};
