import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import QtQuick.Effects

Item {
    property alias leftPage :_leftPage
    property alias dialogs: _dialogs
    property ListModel musicFiles: ListModel {}
    property int currentIndex: -1
    property alias singlePlayer: _singlePlayer
    property alias gridView: _multiPic
    property string currentFolderPath: "" // 当前显示的文件夹路径
    property FolderListModel folderModel: FolderListModel {
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp"]
        showDirs: false
        property bool isLoading: status === FolderListModel.Loading
        
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                loadImagesFromModel()
            }
        }
    }

    id: _content
    anchors.fill: parent

    // 加载文件夹中的图片
    function loadFolderImages(folderPath) {
        if(currentFolderPath===folderPath)
        {
            return;//只有目录真的改变才会执行，解决了如果多次点击文件夹图片会消失的问题
        }

        console.log("Loading images from folder:", folderPath)
        currentFolderPath = folderPath
        
        // 清空当前模型
        musicFiles.clear()
        currentIndex = -1
        
        // 设置文件夹模型的路径
        folderModel.folder = "file://" + folderPath
        
        // 显示图片视图
        singlePlayer.visible = false
    }
    
    // 从文件夹模型加载图片到列表模型
    function loadImagesFromModel() {
        console.log("Model status changed, count:", folderModel.count)
        musicFiles.clear()//清空模型，避免重复加载
        
        // 将图片添加到模型
        for (let i = 0; i < folderModel.count; i++) {
            let fileUrl = folderModel.get(i, "fileURL")
            musicFiles.append({"filePath": fileUrl})
        }
        
        console.log("Loaded " + folderModel.count + " images")
        
        // 更新网格视图布局
        updateGridLayout()
    }
    
    // 根据窗口大小更新网格视图布局
    function updateGridLayout() {
        let availableWidth = rightContainer.width
        // 计算可以放多少列，假设每个项目宽度为180
        let columns = Math.max(1, Math.floor(availableWidth / 180))
        _multiPic.cellWidth = availableWidth / columns
    }
    
    // 窗口大小变化时更新网格布局
    Connections {
        target: rightContainer
        function onWidthChanged() {
            updateGridLayout()
        }
    }

    SplitView {
        id: split
        anchors.fill: parent
        orientation: Qt.Horizontal

        //连接文件操作
        Connections{
            target: fileStream

            function onFileRemoved(path)
            {
                console.log("File removed signal received: " + path)
                
                // Remove file from model if it exists
                for(let i = 0; i < musicFiles.count; ++i) {
                    let modelPath = musicFiles.get(i).filePath.toString().replace("file://", "")
                    path = path.toString().replace("file://", "")
                    
                    console.log("Comparing: model path=" + modelPath + ", removed path=" + path)
                    
                    if(modelPath === path) {
                        console.log("Removing file at index " + i)
                        musicFiles.remove(i)
                        
                        // Update current index if needed
                        if(currentIndex >= i) {
                            currentIndex = Math.max(0, currentIndex - 1)
                            console.log("Updated currentIndex to " + currentIndex)
                        }
                    }
                }
            }

            function onFileRenamed(oldPath,newPath)
            {
                oldPath = oldPath.toString().replace("file://", "")
                newPath = newPath.toString().replace("file://", "")
                console.log("File renamed from: " + oldPath + " to: " + newPath)

                for(let i=0; i<musicFiles.count; ++i)
                {
                    let modelPath = musicFiles.get(i).filePath.toString().replace("file://", "")
                    if (modelPath === oldPath) {
                        musicFiles.setProperty(i, "filePath", "file://" + newPath)
                        console.log("Updated model at index " + i + " to: file://" + newPath)

                        // Update player source if needed
                        if(singlePlayer.source.toString().replace("file://", "") === oldPath) {
                            singlePlayer.source = "file://" + newPath
                            console.log("Updated player source to: file://" + newPath)
                        }
                        break;
                    }
                }
            }
        }

        Page {
            id: _leftPage
            implicitWidth: 200
            z:999
            footer:ToolBar{
                RowLayout{
                    anchors.fill:parent

                    ToolButton{
                        text:"文件夹"
                        onClicked: {
                            leftStack.currentIndex=0
                        }

                    }
                    ToolButton{
                        text:"工具栏"
                        onClicked: {
                            leftStack.currentIndex=1
                        }
                    }
                }
            }

            StackLayout {
                id:leftStack
                anchors.fill: parent
                currentIndex: 1

                Tree{
                    Layout.alignment:Qt.AlignLeft
                    id:_tree
                    musicFiles: musicFiles // 连接到 Content 的 musicFiles 属性
                    
                    // 处理 loadFolder 信号
                    onLoadFolder: function(folderPath) {
                        loadFolderImages(folderPath)
                        _tree.isLoadingFolder = false // 重置加载状态
                    }
                }

                // 工具栏
                ScrollView {
                    id: toolPanel
                    ColumnLayout {
                        width: toolPanel.width

                        Label {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            text: "Picture oprations"
                        }

                        //顺时针
                        ToolButton {
                            Layout.fillWidth: true
                            // text: "Rotate to the left"
                            action:actions.rotateCW
                        }

                        //逆时针
                        ToolButton {
                            Layout.fillWidth: true
                            // text: "Rotate to the right"
                            action:actions.rotateCCW
                        }

                        //水平翻转重命名需要通过建立旧路径（旧文件名）的qfile对象以及通过qfileinfo获取文件信息执行，最后将其更新为新路径（新文件名）【因为文件的路径内包含着文件名，本质还是改变路径】
                        //需要通过与qml内的交互执行，所以在组件内部建立了方法

                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.horizontalFlip
                        }

                        //垂直翻转
                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.verticalFlip
                        }

                        //放大
                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.zoomIn
                        }

                        //缩小
                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.zoomOut
                        }

                        //裁剪
                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.crop
                        }

                        ToolButton{
                            Layout.fillWidth: true
                            text:"Annotation"
                            icon.name: "draw-brush"
                            onClicked: {
                                if (singlePlayer.visible && singlePlayer.source.toString() !== "") {
                                    openAnnotationWiondow(singlePlayer.source)
                                } else {
                                    console.log("请先选择一张图片")
                                }
                            }
                        }//图片标注

                        ToolSeparator {
                            orientation: Qt.Horizontal
                            Layout.fillWidth: true
                        }

                        //文件操作

                        Label {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            text: "File operations"
                        }

                        ToolButton {
                            Layout.fillWidth: true
                            action:actions.del
                        }//删除

                        ToolButton {
                            Layout.fillWidth: true
                            text: "Rename"
                            action:actions.rename
                        }//重命名
                        
                        ToolButton{
                            Layout.fillWidth: true
                            action:actions.saveAs
                        }//保存为

                        ToolButton {
                            Layout.fillWidth: true
                            action:actions.info
                        }//信息
                    }
                }
            }
        }

        // 右侧内容区域
        Item {
            id: rightContainer
            
            // 当前文件夹标题
            Rectangle {
                id: folderTitle
                anchors.top: parent.top
                width: parent.width
                height: 30
                color: "#f0f0f0"
                visible: currentFolderPath !== ""
                
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (currentFolderPath === "") return ""
                        let parts = currentFolderPath.split('/')
                        let folderName = parts[parts.length - 1]
                        return "当前目录: " + folderName
                    }
                    font.pixelSize: 14
                    font.bold: true
                }
            }
            
            GridView {
                id: _multiPic
                anchors.top: folderTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                model: musicFiles
                delegate: musicDelegate
                cellHeight: 180
                clip: true
                
                // 在组件完成后初始化布局
                Component.onCompleted: {
                    updateGridLayout()
                }
                
                // 添加滚动条
                ScrollBar.vertical: ScrollBar {}
                
                // 加载状态指示器
                BusyIndicator {
                    anchors.centerIn: parent
                    running: folderModel.isLoading
                    visible: running
                    width: 48
                    height: 48
                }
                
                // 空文件夹提示
                Text {
                    anchors.centerIn: parent
                    text: "当前文件夹没有图片"
                    font.pixelSize: 16
                    visible: musicFiles.count === 0 && currentFolderPath !== ""
                }
            }

            Imager{
                id: _singlePlayer
                anchors.fill: parent
                visible: false

                Keys.onLeftPressed: {
                    if(currentIndex > 0) {
                        currentIndex--
                        source = musicFiles.get(currentIndex).filePath
                    }
                }

                Keys.onRightPressed: {
                    if(currentIndex < musicFiles.count - 1) {
                        currentIndex++
                        source = musicFiles.get(currentIndex).filePath
                    }
                }
                Menu {
                    id: mouseMenu
                    MenuItem {
                        text: "复制"
                        onTriggered: {
                            if (singlePlayer.visible && singlePlayer.source !== "") {
                                fileStream.copyImageOnclick(singlePlayer.source.toString().replace("file://", ""))
                                dialogs.messageDialog.show("图片已复制到剪贴板")
                            }
                        }
                    }
                    MenuItem {
                        icon.name:"document-save-as"
                        text: "另存为"
                        onTriggered: {
                            if (singlePlayer.visible && singlePlayer.source !== "") {
                                var filePath = singlePlayer.source
                                dialogs.saveAsDialog.save(filePath)
                            }
                        }
                    }
                }
                
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: function(eventPoint) {
                        mouseMenu.x = eventPoint.position.x
                        mouseMenu.y = eventPoint.position.y
                        mouseMenu.open()
                    }
                }
            }
        }
    }

    Component {
        id: musicDelegate
        Item {
            width: gridView.cellWidth - 10
            height: gridView.cellHeight - 10
            
            // 边框
            Rectangle {
                id: itemBg
                anchors.fill: parent
                color: "transparent"
                border.color: hoverHandler.hovered ? "#4CAF50" : "#e0e0e0"
                border.width: hoverHandler.hovered ? 2 : 1
                radius: 4
            }
            
            Image {
                id: img
                source: filePath
                anchors.fill: parent
                anchors.margins: 5
                anchors.bottomMargin: 25 // 留出空间显示文件名
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                
                // 图片加载指示器
                BusyIndicator {
                    anchors.centerIn: parent
                    running: img.status === Image.Loading
                    visible: running
                    width: 32
                    height: 32
                }
            }
            
            // 文件名标签
            Text {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 2
                }
                width: parent.width - 10
                text: {
                    let path = filePath.toString()
                    if (path.startsWith("file://")) {
                        path = path.substring(7)
                    }
                    let parts = path.split('/')
                    return parts[parts.length - 1]
                }
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 11
            }
            
            // 使用 TapHandler 处理点击事件
            TapHandler {
                id: tapHandler
                onDoubleTapped: {
                    singlePlayer.focus = true
                    singlePlayer.source = filePath
                    singlePlayer.visible = true
                    currentIndex = index
                }
            }
            
            // 使用 HoverHandler 处理悬停效果
            HoverHandler {
                id: hoverHandler
            }
        }
    }

    Dialogs {
        id: _dialogs
        openDialog.onAccepted: {
            musicFiles.clear()
            for(let i = 0; i < openDialog.selectedFiles.length; i++) {
                musicFiles.append({"filePath": openDialog.selectedFiles[i]})
            }
            currentIndex = 0
            if(musicFiles.count > 0) {
                _singlePlayer.source = musicFiles.get(0).filePath
            }
        }

        confirmDialog.onAccepted: {
            var filePath = confirmDialog.filePath
            if(fileStream.moveToTrash(filePath)) {
                messageDialog.show("已经成功移动到回收站")
            } else {
                messageDialog.show("删除失败：" + fileStream.lastError(), true)
            }
        }
    }

    //标注图片窗口
    AnnotationWindow{
        id:annotationWindow
    }

    function openAnnotationWiondow(imagePath){
        annotationWindow.open(imagePath)
    }
}

