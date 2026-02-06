#include "fileStream.h"
#include <QGuiApplication>
#include <QFile>
#include <QDir>
#include <QUrl>
#include <QDateTime>
#include <QStandardPaths>
#include <QSaveFile>
#include <QImage>
#include <QClipboard>
#include <QBuffer>
#include <QImageWriter>
#include <QDebug>
#include <QMimeDatabase>

FileStream::FileStream(QObject *parent) : QObject(parent) {}

bool FileStream::moveToTrash(const QString &filePath)
{
    m_lastError.clear();

    if (!QFile::exists(filePath)) {
        m_lastError = "file does not exist" + filePath;
        return false; //check the file whether exists;
    }

    const QString trashDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/Trash";
    const QString fileDir = trashDir + "/files"; //实际存放文件的目录
    const QString infoDir = trashDir + "/info";  //存放元信息的目录
    //get the path of trash recycler
    //trash/files负责存放被删除的文件，trash/info负责存放.trashinfo对应的元数据

    if (!QDir().mkpath(fileDir) || !QDir().mkpath(infoDir)) {
        //mkdir -p
        m_lastError = "cannot create trash directory";
        return false;
    } //create trash directory;

    QFileInfo originalFile(filePath);
    QString newName = originalFile.fileName();
    int counter = 1;
    while (QFile::exists(fileDir + "/" + newName)) {
        newName = originalFile.baseName() + "_" + QString::number(counter++) + "." + originalFile.completeSuffix();
    } //solve the problem of file name when get conflicted in recycler;

    QString destFilePath = fileDir + "/" + newName;
    if (!QFile::rename(filePath, destFilePath)) {
        m_lastError = "cannot move the file into trash";
        return false;
    } //move the file to the trash

    QString infoFilePath = infoDir + "/" + newName + ".trashinfo";
    QSaveFile infoFile(infoFilePath); //原子性写入，没完成之前不会真正覆盖
    if (!infoFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QFile::rename(destFilePath, filePath);
        m_lastError = "cannot create original data file";
        return false;
    } //create original data file,like original path and delete time

    QTextStream out(&infoFile); //写入元数据了
    out << "[Trash Info]\n"
        << "Path=" << QUrl::toPercentEncoding(originalFile.absoluteFilePath()) << "\n"
        << "DeletionDate=" << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n";

    if (!infoFile.commit()) { //提交元数据
        QFile::rename(destFilePath, filePath);
        m_lastError = "cannot write original data";
        return false;
    }

    emit fileRemoved(filePath);

    return true;
}

QString FileStream::lastError() const
{
    return m_lastError;
}

bool FileStream::renameFile(const QString &oldPath, const QString &newName)
{
    QFile file(oldPath);                           //construct the file of the oldpath
    QFileInfo info(oldPath);                       //get the file information
    QString newPath = info.path() + "/" + newName; //combine the newpath
    if (!newPath.endsWith("." + info.suffix())) {
        //get the suffix of the file.If the file is lack of the suffix,it will be compensated
        //this method is used to handle the problem under the situation when users add the suffix like "1.png"
        newPath += "." + info.suffix();
    }

    if (file.rename(newPath)) {
        emit fileRenamed(oldPath, newPath);
        return true;
    }
    return false;
}

void FileStream::copyImageOnclick(const QString &imagePath)
{
    QImage image(imagePath);
    if (!image.isNull()) { QGuiApplication::clipboard()->setImage(image); }
}

bool FileStream::saveAs(const QString &sourcePath, const QString &newPath)
{
    m_lastError.clear();

    //处理源路径，检查是否已经包含file://前缀
    QString srcPath;
    if (sourcePath.startsWith("file://")) {
        srcPath = QUrl(sourcePath).toLocalFile();
    } else {
        srcPath = sourcePath; //直接使用没有前缀的路径
    }

    //处理目标路径
    QString dstPath;
    if (newPath.startsWith("file://")) {
        dstPath = QUrl(newPath).toLocalFile();
    } else {
        dstPath = newPath;
    }

    QFile sourceFile(srcPath);
    QFile destFile(dstPath);

    if (!sourceFile.exists()) {
        m_lastError = "源文件不存在: " + srcPath;
        return false;
    }

    // Try to copy the file
    if (destFile.exists()) {
        if (!destFile.remove()) {
            m_lastError = "无法覆盖已存在的文件: " + dstPath;
        return false;
        }
    }

    return sourceFile.copy(dstPath);
}

QStringList FileStream::getImageFiles(const QString &directoryPath)
{
    m_lastError.clear();
    QStringList imageFiles;

    //处理URL路径，将file://前缀的URL转换为本地文件路径
    QString localPath = directoryPath;
    if (directoryPath.startsWith("file://")) {
        localPath = QUrl(directoryPath).toLocalFile();
    }

    //检查目录是否存在
    QDir dir(localPath);
    if (!dir.exists()) {
        m_lastError = "目录不存在: " + localPath;
        return imageFiles;
    }

    //获取目录中的所有文件，后续再通过MIME类型过滤
    dir.setFilter(QDir::Files | QDir::NoDotAndDotDot);

    //获取符合条件的文件列表
    QFileInfoList fileList = dir.entryInfoList();
    QMimeDatabase mimeDb;

    //通过MIME类型进一步验证文件是否为图片，并将有效图片添加到列表
    //MIME类型是通过分析文件内容，而非仅通过扩展名来分析文件格式的特性
    //本质上是分析文件头，但是我们并不分析其16进制数据（太难了）
    //通过对应的文件头名就可以，如image/jpeg
    for (const QFileInfo &fileInfo : fileList) {
        QString filePath = fileInfo.absoluteFilePath();

        //检查MIME类型是否为图像类型
        QMimeType mimeType = mimeDb.mimeTypeForFile(filePath);
        if (mimeType.name().startsWith("image/")) {
            imageFiles.append(filePath);
        }
    }
    
    qDebug() << "在目录" << localPath << "中找到" << imageFiles.size() << "张图片";
    return imageFiles;
}
