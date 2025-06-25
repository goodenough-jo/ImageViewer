import QtQuick
import QtQuick.Controls
import FileTree 1.0

/**
 * TreeView - 目录树组件
 * 显示文件系统的目录结构
 */
TreeView {
    id: treeView
    anchors.fill: parent
    
    property bool isLoadingFolder: false
    property var musicFiles: null  // 将在 Content.qml 中连接到实际的模型

    signal loadFolder(string folderPath)  // 新增信号，用于通知外部加载文件夹
    
    // 设置数据模型为FileLead类型
    model: FileLead {
        id: fileModel
    }
    
    // 组件完成初始化后设置根路径为根目录
    Component.onCompleted: {
        fileModel.setRootPath("file:///")
    }
    
    // 设置选择模型以支持选择操作
    selectionModel: ItemSelectionModel {}
    
    // 自定义列宽度，使其填充整个宽度
    columnWidthProvider: function(column) { return treeView.width; }
    
    // 配置委托，定义每个目录项的显示样式
    delegate: TreeViewDelegate {
        id: treeDelegate
        
        // 设置缩进量
        indentation: 20
        leftPadding: depth * indentation
        
        // 获取文件夹名称的函数，从完整路径中提取
        function getFolderName(path) {
            if (!path) return "";
            // 按"/"分割路径，获取最后一个非空部分作为文件夹名
            const parts = path.toString().split("/");
            for (let i = parts.length - 1; i >= 0; i--) {
                if (parts[i]) return parts[i];
            }
            return "";
        }
        
        // 内容项，显示文件夹图标和名称
        contentItem: Row {
            spacing: 4

            Image {
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/images/folder.svg"
            }
            
            // 目录名称 - 只显示文件夹名称，而非完整路径
            Text {
                text: treeDelegate.getFolderName(model.filePath) || model.fileName || ""
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
            }
        }
        
        // 点击处理，输出选中的路径并触发信号
        onClicked: {
            console.log("Selected path:", model.filePath)
            
            // 现在所有显示的项目都是文件夹，直接触发加载信号
            if (!isLoadingFolder) {
                isLoadingFolder = true

                let path = model.filePath.toString()
                if (path.startsWith("file://")) {
                    path = path.substring(7)
                }
                
                // 触发加载文件夹信号
                loadFolder(path)
            }
        }
    }
}
