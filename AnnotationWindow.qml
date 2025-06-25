import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Dialogs
// import Qt.labs.platform //StandarPaths导入
import QtCore  //StandarPaths导入


//这里的AnnotationWindow功能简单，所以暂不进行进一步分类
Window{
    width: 600;height:600;visible: false
    id:annotationWindow
    title:"图标标注"

    property url imageSource    //保存导入的图片路径

    property string savePath: StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                                + "/annotated_"   //保存的文件路径
    
    FileDialog{
        id:anotatedSaveDialog
        title:"保存标注图片"
        fileMode: FileDialog.SaveFile
        // defaultSuffix:
        // nameFilters: ["PNG图像（*.png）","JPEG图像 (*.jpg)"]

        onAccepted: {
            var savePath = selectedFile.toString()


            contentArea.grabToImage(function(result){
                if(result.saveToFile(savePath)){
                    console.log("标注已保存到"+savePath)
                }
            })
        }
    }

    ToolBar {
        id:toolBar
        width: parent.width
        Row {
            anchors.centerIn: parent
            spacing: 10

            ToolButton {
                text: "保存"
                icon.name:"document-save"
                // onClicked: saveAnnotatedImage()
                //设置defaultName（保存名字），并将currentFile设置为系统默认picture保存路径，并打开FileDialog
                onClicked: {
                    var defaultName = "annotate_"+Qt.formatDateTime(new Date(),"yyyyMMdd_hhmmss")

                    if(imageSource.toString()){
                        defaultName +="_"+imageSource.toString().split('/').pop()
                    }

                    anotatedSaveDialog.currentFile=StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                                                    +"/"+defaultName
                    anotatedSaveDialog.open()
                }
            }

            ToolButton {
                text: "清除"
                icon.name:"edit-clear"
                onClicked: shapePath.pathElements = []
            }

            ToolButton {
                text: "关闭"
                icon.name:"window-close"
                onClicked: annotationWindow.close()
            }
        }
    }



    //用于绘制
    Item{
        id: contentArea
        anchors.top: toolBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        Image{
            source: imageSource
            anchors.fill:parent
            // anchors.top: toolBar.bottom
            // anchors.bottom: parent.bottom
            // anchors.left: parent.left
            // anchors.right: parent.right
            fillMode:Image.PreserveAspectFit //保持原本缩放比例

            Shape{
                anchors.fill:parent

                ShapePath{
                    id:shapePath
                    fillColor: "transparent" //填充透明
                    strokeColor: "red"
                    strokeWidth: 5
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                }
                Component{
                    id:pathLineComponent
                    PathLine{}
                }//用于动态生成PathLine

                PointHandler {
                    id: pointHandler
                    acceptedDevices: PointerDevice.Mouse
                    target: null

                    onActiveChanged: {
                        if (active) {
                            shapePath.pathElements = []
                            shapePath.startX = point.position.x
                            shapePath.startY = point.position.y
                        }
                    }

                    onPointChanged: {
                        if (active) {
                            var line = pathLineComponent.createObject(shapePath)
                            line.x = point.position.x
                            line.y = point.position.y
                            shapePath.pathElements.push(line)   //自动绘图，特别关键
                        }
                    }
                }
            }

        }
    }

    //打开标注
    function open(imagePath){
        imageSource = imagePath
        console.log("imageSource:"+imageSource)
        show()//显示窗口
    }

    // //保存标注图片
    // function saveAnnotatedImage(){
    //     var newPath = savePath+Qt.formatDateTime(new Date(),"yyyyMMdd_hhmmss")
    //                     +"_"+imageSource.toString().split('/').pop()    //savePath+日期与名字

    //     console.log("保存路径："+newPath)


    //     //截图并保存
    //     contentArea.grabToImage(function(result){
    //         result.saveToFile(newPath)
    //         if (result.saveToFile(newPath)) {
    //             console.log("标注已保存到："+newPath)
    //             annotationSaveDialog.text="标注图片已保存："+newPath
    //             annotationSaveDialog.open()
    //         } else {
    //             console.log("保存失败")
    //             annotationSaveDialog.text="保存失败"
    //         }
    //     })
    // }


    // //保存成功提示
    // MessageDialog{
    //     id:annotationSaveDialog
    //     title:"保存成功"
    //     buttons:MessageDialog.Ok
    // }
}
