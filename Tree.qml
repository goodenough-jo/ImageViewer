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

            // 文件夹图标
            Image {
                width: 16
                height: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            
            // 目录名称 - 只显示文件夹名称，而非完整路径
            Text {
                text: treeDelegate.getFolderName(model.filePath) || model.fileName || ""
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
            }
        }
        
        // 点击处理，输出选中的路径
        onClicked: {
            console.log("Selected path:", model.filePath)
            // 也可以使用 fileModel.filePath(treeView.index(row, 0)) 获取路径
        }
    }
}
