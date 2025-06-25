#pragma once
#include <QFileSystemModel>
#include <QQmlEngine>
#include <QAbstractItemModel>
#include <QUrl>

/**
 * @brief FileLead - 文件树模型类，用于展示文件系统目录结构
 * 继承自QFileSystemModel，提供目录树的数据模型
 */
class FileLead : public QFileSystemModel
{
    Q_OBJECT
    QML_ELEMENT // 注册为QML元素，使其可在QML中使用

public:
    explicit FileLead(QObject *parent = nullptr);

    // 获取文件路径，可在QML中调用
    Q_INVOKABLE QString filePath(const QModelIndex &index) const;
    
    // 重写index方法，用于获取模型索引
    Q_INVOKABLE QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    
    // 为QML添加角色映射
    enum Roles {
        FileNameRole = Qt::UserRole + 1, // 文件名角色
        FilePathRole                      // 文件路径角色
    };
    
    // 设置根路径，支持QML调用
    Q_INVOKABLE void setRootPath(const QString &path);
    
    // 获取根路径，支持QML调用
    Q_INVOKABLE QString rootPath() const;
    
    // 重写data方法，提供自定义角色数据
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    
    // 重写roleNames方法，将角色映射到QML中可用的属性名
    QHash<int, QByteArray> roleNames() const override;
};
