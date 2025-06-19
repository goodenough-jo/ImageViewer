import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: imageInfo
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside//这是popup中能够简单支持弹窗外不用关闭按钮即可关闭的特性
    width: 380
    height: 480
    padding: 0
    //这里面的参数都是随便搞的，如果试验出更好的可以调一下
    
    property var fileData: ({})//毕竟是一堆表，都要用map处理了
    property string filePath: ""
    
    //唯一的缺点就是没有用property alias，不过无所谓了
    function showInfo(path) {
        filePath = path
        fileData = fileInfo.getInfo(path.toString().replace("file://", ""))
        updateModel()
        open()
    }//老方法，不用过多解释

    // 半透明背景，好看的很
    background: Rectangle {
        color: "#80000000"
    }

    // 内容区域
    contentItem: Rectangle {
        id: contentRect
        color: "#FFFFFF"
        radius: 8
        border.width: 0
        anchors.fill: parent
        
        // 内容区域内边距
        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10
            
            // 标题栏
            Rectangle {
                width: parent.width
                height: 40//标题栏高度
                color: "#F5F5F5"
                radius: 8
                border.width: 0
                
                Text {
                    anchors.centerIn: parent
                    text: "图片信息"
                    font.pixelSize: 16
                    font.bold: true
                }
            }
            
            // 基本信息区域
            Rectangle {
                width: parent.width
                height: 100//基本信息高度
                color: "#F9F9F9"
                radius: 6
                border.width: 0
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8
                    
                    Text {
                        width: parent.width
                        elide: Text.ElideRight//可以在末尾截断显示省略号的特性，你愿意你也可以在中间
                        maximumLineCount: 1
                        text: "文件名: " + (fileData.name || "未知")
                        font.pixelSize: 14
                        font.bold: true
                    }
                    
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "文件大小: " + (fileData.capacity ? (Math.round(fileData.capacity / 1024) + " KB") : "未知")
                        //简简单单的操作系统算法算占用大小
                        font.pixelSize: 13
                        color: "#333333"
                    }
                    
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: "格式: " + (fileData.format || "未知")
                        font.pixelSize: 13
                        color: "#333333"
                    }
                }
            }
            
            // 详细信息标题
            Rectangle {
                width: parent.width
                height: 36//详细信息标题高度
                color: "#EEEEEE"
                radius: 4
                border.width: 0
                
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: "详细信息"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#333333"
                }
            }
            
            // 详细信息列表
            Rectangle {
                width: parent.width
                // 填满剩余空间
                height: parent.height - 40 - 100 - 36 - 30 // 总高度减去其他元素高度和间距
                color: "#F9F9F9"
                radius: 6
                border.width: 0
                
                ListView {
                    id: detailsList//这是整个展示的核心
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    model: infoModel
                    spacing: 5
                    
                    // 无数据时显示提示
                    Rectangle {
                        anchors.centerIn: parent
                        visible: infoModel.count === 0
                        width: parent.width * 0.8
                        height: 30
                        color: "#F5F5F5"
                        radius: 4
                        border.width: 0
                        
                        Text {
                            anchors.centerIn: parent
                            text: "无详细信息"
                            color: "#666666"
                            font.pixelSize: 14
                        }
                    }
                    
                    delegate: Rectangle {
                        width: detailsList.width
                        height: Math.max(40, valueText.implicitHeight + 16)
                        color: index % 2 === 0 ? "#FFFFFF" : "#F5F5F5"
                        radius: 4
                        border.width: 0
                        
                        Row {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            
                            Text {
                                width: parent.width * 0.35
                                height: parent.height
                                text: label
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                                color: "#333333"
                                verticalAlignment: Text.AlignVCenter
                            }
                            
                            Text {
                                id: valueText
                                width: parent.width * 0.65 - 8
                                height: parent.height
                                text: value
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                wrapMode: Text.Wrap
                                color: "#555555"
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }
                }
            }
        }
        
        // 防止点击内容区域关闭弹窗
        MouseArea {
            anchors.fill: parent
            onClicked: function(event) {
                event.accepted = true;
            }
        }
    }
    
    ListModel {
        id: infoModel
    }
    
    // 更新模型的函数
    function updateModel() {
        console.log("更新信息模型")
        infoModel.clear()
        
        if (fileData.size) {
            infoModel.append({
                label: "尺寸", 
                value: String(fileData.size.width) + " × " + String(fileData.size.height) + " 像素"
            })
        }
        
        if (fileData.lastmodified) {
            infoModel.append({
                label: "修改时间", 
                value: String(fileData.lastmodified.toLocaleString(Qt.locale(), "yyyy-MM-dd hh:mm:ss"))
            })
        }
        
        if (fileData.birthtime) {
            infoModel.append({
                label: "创建时间", 
                value: String(fileData.birthtime.toLocaleString(Qt.locale(), "yyyy-MM-dd hh:mm:ss"))
            })
        }
        
        if (fileData.model && String(fileData.model).trim() !== "") {
            infoModel.append({
                label: "相机型号", 
                value: String(fileData.model)
            })
        }
        
        if (fileData.datetime && String(fileData.datetime).trim() !== "") {
            infoModel.append({
                label: "拍摄时间", 
                value: String(fileData.datetime)
            })
        }
        
        if (fileData.GPS && String(fileData.GPS).trim() !== "") {
            infoModel.append({
                label: "GPS信息", 
                value: String(fileData.GPS)
            })
        }
        
        if (fileData.quality) {
            infoModel.append({
                label: "色彩深度",
                value: String(fileData.quality)
            })
        }
        
        console.log("模型已更新，数量: " + infoModel.count)//在测试完全后可以注释掉
    }
}
