#include "filelead.h"

FileLead::FileLead(QObject *parent) : QFileSystemModel(parent)
{
    //设置过滤器：只显示目录，不显示"."和".."目录
    setFilter(QDir::AllDirs | QDir::NoDotAndDotDot); 
    setNameFilters({"*"});
    setNameFilterDisables(false);
}

QString FileLead::filePath(const QModelIndex &index) const
{
    //获取文件的完整路径，直接调用基类方法
    return QFileSystemModel::filePath(index);
}

QModelIndex FileLead::index(int row, int column, const QModelIndex &parent) const
{
    //获取模型索引，直接调用基类方法
    return QFileSystemModel::index(row, column, parent);
}

void FileLead::setRootPath(const QString &path)
{
    //处理文件URL，支持file:///前缀的URL格式
    QString localPath = path;
    if (path.startsWith("file:///")) {
        localPath = QUrl(path).toLocalFile(); //将URL转换为本地文件路径
    }
    QFileSystemModel::setRootPath(localPath); //设置根路径
}

QString FileLead::rootPath() const
{
    //获取根路径，直接调用基类方法
    return QFileSystemModel::rootPath();
}

QVariant FileLead::data(const QModelIndex &index, int role) const
{
    //无效索引返回空值
    if (!index.isValid()) {
        return QVariant();
    }

    //根据角色返回对应的数据
    switch (role) {
    case FileNameRole:
        return fileName(index); //返回文件名
    case FilePathRole:
        return filePath(index); //返回文件路径
    default:
        return QFileSystemModel::data(index, role); //其他角色使用基类处理
    }
}

QHash<int, QByteArray> FileLead::roleNames() const
{
    //获取基类的角色名映射
    QHash<int, QByteArray> roles = QFileSystemModel::roleNames();

    //添加自定义角色名映射，使其可在QML中通过model.fileName和model.filePath访问
    roles[FileNameRole] = "fileName";
    roles[FilePathRole] = "filePath";
    return roles;
}
