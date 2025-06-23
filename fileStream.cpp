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

FileStream::FileStream(QObject *parent) : QObject(parent) {}

bool FileStream::moveToTrash(const QString &filePath)
{
    m_lastError.clear();

    if (!QFile::exists(filePath)) {
        m_lastError = "file does not exist" + filePath;
        return false; //check the file whether exists;
    }

    const QString trashDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + "/Trash";
    const QString fileDir = trashDir + "/files";
    const QString infoDir = trashDir + "/info";
    //get the path of trash recycler

    if (!QDir().mkpath(fileDir) || !QDir().mkpath(infoDir)) {
        m_lastError = "cannot create trash directory";
        return false;
    } //create trash directory;

    QFileInfo originalFile(filePath);
    QString newName = originalFile.fileName();
    int counter = 1;
    while (QFile::exists(fileDir + "/" + newName)) {
        newName = originalFile.baseName() + "_" + QString::number(counter++) + "." + originalFile.completeSuffix();
    } //solve the problem of file name when get conflicted;

    QString destFilePath = fileDir + "/" + newName;
    if (!QFile::rename(filePath, destFilePath)) {
        m_lastError = "cannot move the file into trash";
        return false;
    } //move the file to the trash

    QString infoFilePath = infoDir + "/" + newName + ".trashinfo";
    QSaveFile infoFile(infoFilePath);
    if (!infoFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QFile::rename(destFilePath, filePath);
        m_lastError = "cannot create original data file";
        return false;
    } //create original data file

    QTextStream out(&infoFile);
    out << "[Trash Info]\n"
        << "Path=" << QUrl::toPercentEncoding(originalFile.absoluteFilePath()) << "\n"
        << "DeletionDate=" << QDateTime::currentDateTime().toString(Qt::ISODate) << "\n";

    if (!infoFile.commit()) {
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

    // 处理源路径，检查是否已经包含file://前缀
    QString srcPath;
    if (sourcePath.startsWith("file://")) {
        srcPath = QUrl(sourcePath).toLocalFile();
    } else {
        srcPath = sourcePath; // 直接使用没有前缀的路径
    }

    // 处理目标路径
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

    // 使用QFile::copy前检查源文件和目标文件是否相同
    if (srcPath == dstPath) {
        // 如果源文件和目标文件相同，则无需复制
        return true;
    }

    // 如果源文件和目标文件不同，使用QSaveFile来安全地覆盖文件
    QSaveFile saveFile(dstPath);
    if (!saveFile.open(QIODevice::WriteOnly)) {
        m_lastError = "无法创建目标文件: " + dstPath;
        return false;
    }

    // 打开源文件
    if (!sourceFile.open(QIODevice::ReadOnly)) {
        m_lastError = "无法打开源文件: " + srcPath;
        saveFile.cancelWriting();
        return false;
    }

    // 复制文件内容
    QByteArray data = sourceFile.readAll();     //获得最初的二进制数据
    qint64 bytesWritten = saveFile.write(data); //返回实际写入的字节数
    sourceFile.close();

    if (bytesWritten != data.size()) { //利用字节数匹配完成检测文件是否写入完整
        m_lastError = "写入数据不完整";
        saveFile.cancelWriting();
        return false;
    }

    // 提交更改，这会安全地替换目标文件
    if (!saveFile.commit()) {
        m_lastError = "无法保存文件: " + dstPath;
        return false;
    }

    return true;
}
