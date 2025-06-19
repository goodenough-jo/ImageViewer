#include "fileStream.h"
#include <QFile>
#include <QDir>
#include <QUrl>
#include <QDateTime>
#include <QStandardPaths>
#include <QSaveFile>

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
