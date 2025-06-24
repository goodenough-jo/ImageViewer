#pragma once
#include <QFile>
#include <QObject>
#include <QStringList>

class FileStream : public QObject
{
    Q_OBJECT

public:
    explicit FileStream(QObject *parent = nullptr);

    Q_INVOKABLE bool moveToTrash(const QString &filePath);
    Q_INVOKABLE QString lastError() const;

    Q_INVOKABLE bool renameFile(const QString &oldPath, const QString &newname);

    Q_INVOKABLE void copyImageOnclick(const QString &imagePath);
    Q_INVOKABLE bool saveAs(const QString &sourcePath, const QString &newPath);
    
    /**
     * @brief 获取指定目录下的所有图片文件
     * @param directoryPath 目录路径，支持file://前缀的URL格式
     * @return 图片文件的完整路径列表
     * 
     * 此方法会扫描目录中的所有文件，通过扩展名和MIME类型筛选出图片文件
     * 支持的图片格式包括：jpg, jpeg, png, gif, bmp
     */
    Q_INVOKABLE QStringList getImageFiles(const QString &directoryPath);

signals:
    void fileRemoved(const QString &path);
    void fileRenamed(const QString &oldpath, const QString &newPath);

private:
    QString m_lastError;
};
