import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Qt.labs.folderlistmodel  // 添加文件夹模型支持


Item {
    property alias dialogs:_dialogs

    property ListModel musicFiles : ListModel{}//存储图片文件--filePath
    property int currentIndex : -1//索引
    property alias singlePlayer : _singlePlayer

    id:_content
    anchors.fill:parent

    //新增SplitView布局，以显示目录树与工具栏

    SplitView{
        anchors.fill:parent
        orientation: Qt.Horizontal

        //左侧面板(目录树/工具)
        Page{
            id:leftPage
            // visible: sidebarVisible
            implicitWidth:200

            //StackLayout：管理多个项目
            StackLayout{
                anchors.fill:parent//防止溢出

                // TreeView {
                //     id: directoryTree
                //     model: FolderListModel {
                //         id: folderModel
                //         rootFolder: "file:///" + Qt.application.arguments[1] || StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]  // 默认显示用户主目录
                //         showDirsFirst: true
                //         nameFilters: ["*.jpg", "*.png", "*.bmp"]  // 只显示图片文件
                //     }

                //     // 自定义节点样式
                //     delegate: TreeViewDelegate {
                //         id: treeDelegate
                //         implicitHeight: 30

                //         contentItem: RowLayout {
                //             spacing: 5
                //             Image {
                //                 source: model.isDir ? "qrc:/icons/folder.png" : "qrc:/icons/file.png"
                //                 Layout.preferredWidth: 16
                //                 Layout.preferredHeight: 16
                //             }
                //             Text {
                //                 text: model.fileName
                //                 elide: Text.ElideRight
                //                 Layout.fillWidth: true
                //             }
                //         }

                //         // 点击节点时加载该目录下的图片
                //         TapHandler {
                //             onTapped: {
                //                 if (model.isDir) {
                //                     folderModel.folder = "file:///" + model.filePath;
                //                 } else {
                //                     musicFiles.append({"filePath": model.fileURL});
                //                 }
                //             }
                //         }
                //     }
                // }

                TreeView{
                    id:folderTree
                    model:FolderListModel{
                        // rootFolder: "/root"
                        // showDirsFirst: true
                        rootFolder: "file:///"
                        nameFilters: ["*.jpg","*.png"]
                        showDirsFirst: true
                        showDotAndDotDot: false
                        showHidden: false

                    }
                    delegate:TreeViewDelegate{

                    }
                }



                //工具栏
                ScrollView{
                    id:toolPanel

                    ColumnLayout{
                        width:toolPanel.width

                        //图片操作
                        Label{
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter//水平居中
                            text:"Image operations"
                        }

                        ToolButton{
                            Layout.fillWidth: true//使按钮充满工具栏

                            text:"Rotate to the left"
                        }
                        ToolButton{
                            Layout.fillWidth: true

                            text:"Rotate to the right"
                        }

                        ToolSeparator{
                            orientation: Qt.Horizontal
                            Layout.fillWidth: true//设置分割线的大小
                        }

                        //文件操作
                        Label{
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter//水平居中
                            text:"File operations"
                        }
                        ToolButton{
                            Layout.fillWidth: true
                            text:"Move to..."
                        }
                        ToolButton{
                            Layout.fillWidth: true
                            text:"Rename"
                        }
                    }
                }




            }
        }


        GridView{
            id:gridView
            // anchors.fill:parent

            model:musicFiles

            delegate: musicDelegate
        }
    }




    Component{
        id:musicDelegate
        Image{
            source: filePath
            width:gridView.cellWidth-10;height:gridView.cellHeight-10
            TapHandler{
                onDoubleTapped: {
                    singlePlayer.focus=true//必须添加 不然左右键没有反应
                    singlePlayer.source=filePath
                    singlePlayer.visible=true
                    currentIndex = index
                    console.log("currentIndex:"+currentIndex)
                }
            }
        }
    }

    Image{
        id:_singlePlayer
        anchors.fill:parent
        visible: false

        // focus: true
        // Keys.enabled: true

        TapHandler{
            onTapped: {
                singlePlayer.visible=false
            }
        }
        // Keys.onLeftPressed: {
        //     currentIndex--;
        //     source:musicFiles.get(currentIndex).filePath
        // }
        Keys.onLeftPressed: {
            if(currentIndex > 0) {
                currentIndex--;
                console.log("currentIndex:"+currentIndex)
                source = musicFiles.get(currentIndex).filePath;
            }
        }
        Keys.onRightPressed: {
            if(currentIndex < musicFiles.count - 1) {
                currentIndex++;
                console.log("currentIndex:"+currentIndex)
                source = musicFiles.get(currentIndex).filePath;
            }
        }
    }

    Dialogs{
        id:_dialogs
        openDialog.onAccepted: {
            for(let i=0;i<openDialog.selectedFiles.length;i++){
                musicFiles.append({"filePath":openDialog.selectedFiles[i]})
                console.log(musicFiles.get(i).filePath)
            }
            currentIndex = 0
        }

    }
}

