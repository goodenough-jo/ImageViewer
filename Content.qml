import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel

Item {
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
            id: leftPage
            implicitWidth: 200

            StackLayout {
                anchors.fill: parent

                // // 目录树
                // TreeView {
                //     id: folderTree
                //     model: FolderListModel {
                //         rootFolder: "file:///"
                //         nameFilters: ["*.jpg", "*.png"]
                //         showDirsFirst: true
                //         showDotAndDotDot: false
                //         showHidden: false
                //     }
                //     delegate: TreeViewDelegate {}
                // }

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

                        ToolSeparator {
                            orientation: Qt.Horizontal
                            Layout.fillWidth: true
                        }

                        Label {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            text: "File operations"
                        }

                        ToolButton {
                            Layout.fillWidth: true
                            text: "Move to..."
                        }

                        ToolButton {
                            Layout.fillWidth: true
                            text: "Rename"
                        }
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

                // TapHandler {
                //     onTapped: singlePlayer.visible = false
                // }

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
}

