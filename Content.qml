import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel

Item {
    property alias leftPage :_leftPage
    property alias dialogs: _dialogs
    property ListModel musicFiles: ListModel {}
    property int currentIndex: -1
    property alias singlePlayer: _singlePlayer
    property alias gridView: _multiPic

    id: _content
    anchors.fill: parent

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


        // 左侧面板(目录树/工具)
        Page {
            id: _leftPage
            implicitWidth: 200
            z:999
            StackLayout {
                anchors.fill: parent



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

                        //水平翻转
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
                            // onClicked: {
                            //     openAnnotationWiondow(musicFiles.get(currentIndex).filePath)//传递URL
                            // }
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
                            action:actions.rename
                        }//重命名

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
            GridView {
                id: _multiPic
                anchors.fill: parent
                model: musicFiles
                delegate: musicDelegate
            }

            Imager {
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
            }


        }
    }

    Component {
        id: musicDelegate
        Image {
            source: filePath
            fillMode:Image.PreserveAspectFit //保持原本缩放比例
            width: gridView.cellWidth - 10
            height: gridView.cellHeight - 10
            TapHandler {
                onDoubleTapped: {
                    singlePlayer.focus = true
                    singlePlayer.source = filePath
                    singlePlayer.visible = true
                    currentIndex = index
                }
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

