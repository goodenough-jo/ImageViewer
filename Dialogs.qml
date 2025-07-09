import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property alias openDialog: _openDialog
    property alias messageDialog: _messageDialog
    property alias confirmDialog: _confirmDialog
    property alias renameDialog:_renameDialog
    property alias infoPopup:_infoPopup
    property alias saveDialog:_saveImageDialog
    property alias saveAsDialog:_saveDialog


    FileDialog{
        id: _openDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Select images (*.jpg *.png)"]
    }

    MessageDialog{
        id: _messageDialog
        modality: Qt.WindowModal
        title: "提示"
        buttons: MessageDialog.Ok

        function show(text, isError=false)
        {
            _messageDialog.text = text;
            open()
        }
    }

    MessageDialog{
        id: _confirmDialog
        modality: Qt.WindowModal
        title: "确认"
        text: "是否要删除？"
        buttons: MessageDialog.Yes | MessageDialog.No
        
        property string filePath: ""
        property string fileName: ""
        
        function confirm(path)
        {
            filePath = path
            var name = path.toString().split("/").pop()
            fileName = name
            text = "是否要删除 " + name + "？"
            open()
        }
    }

    Dialog{
        id:_renameDialog
        title:"重命名"
        standardButtons: Dialog.Ok | Dialog.Cancel

        property string originalName:""
        property string filePath:""

        function rename(path) {
            filePath = path
            var name = path.toString().split("/").pop()
            originalName = name
            open()
        }

        ColumnLayout{
            TextField{
                id:namefield
                text:_renameDialog.originalName.split(".")[0]
                selectByMouse: true
                focus:true
            }
        }
        //封装有问题需要优化
        onAccepted:{

            if (namefield.text === "") return;
            const result = fileStream.renameFile(filePath, namefield.text);
            if (!result) {
                _messageDialog.show("重命名失败: " + fileStream.lastError(), true);
            }
        }
    }

    InfoPopup{
        id:_infoPopup//弹窗我单独分为了一个类
    }

    FileDialog{
        id:_saveDialog
        title: "保存图片"
        fileMode: FileDialog.SaveFile
        //defaultSuffix:""
        
        property string sourceFilePath: ""
        property string currentExtension: ""
        property string originalFormat:""


        function getFileExtension(path) {
 
            let pathStr = path.toString();
            return pathStr.substring(pathStr.lastIndexOf(".") + 1).toLowerCase();
        }
        
        function save(path) {
            sourceFilePath = path
            currentExtension = getFileExtension(path)
            defaultSuffix = currentExtension//defaultSuffix只有在用户没有明确指定扩展名时才会生效

            if (originalFormat !== "") {
                currentExtension = originalFormat
                defaultSuffix = originalFormat
            }

            // 根据原始图片格式设置过滤器顺序
            //原先的方案在 nameFilters 中，PNG 格式被列在第一位：["Image files (*.png *.jpg *.bmp)"]
            //当用户选择"Image files"过滤器时，Qt 会使用过滤器中的第一个扩展名（.png）作为默认扩展名
            if (currentExtension === "jpg" || currentExtension === "jpeg") {
                nameFilters = ["JPEG图片 (*.jpg *.jpeg)", "PNG图片 (*.png)", "BMP图片 (*.bmp)"]
            } else if (currentExtension === "png") {
                nameFilters = ["PNG图片 (*.png)", "JPEG图片 (*.jpg *.jpeg)", "BMP图片 (*.bmp)"]
            } else if (currentExtension === "bmp") {
                nameFilters = ["BMP图片 (*.bmp)", "PNG图片 (*.png)", "JPEG图片 (*.jpg *.jpeg)"]
            } else {
                nameFilters = ["图片文件 (*.png *.jpg *.jpeg *.bmp)"]
            }
            
            open()
        }
        //封装需要优化
        onAccepted: {

            if (sourceFilePath === "") return;

            // 获取选择的文件路径
            let filePath = selectedFile.toString();
            let fileExtension = "";
            
            // 确保使用字符串方法
            if (filePath.indexOf('.') !== -1) {
                fileExtension = filePath.substring(filePath.lastIndexOf('.') + 1).toLowerCase();
            }
            
            // 添加扩展名
            if (fileExtension === "" || (originalFormat !== "" && fileExtension !== originalFormat)) {
                if (fileExtension !== "") {
                    filePath = filePath.substring(0, filePath.lastIndexOf('.'));
                }
                filePath = filePath + "." + (originalFormat !== "" ? originalFormat : "png");
             }
            
            // 检查是否需要添加扩展名，只有一个一个检查才能保证图片的后缀并不会被改变
            if (!filePath.toLowerCase().endsWith("." + currentExtension) && 
                !filePath.toLowerCase().endsWith(".jpg") && 
                !filePath.toLowerCase().endsWith(".jpeg") && 
                !filePath.toLowerCase().endsWith(".png") && 
                !filePath.toLowerCase().endsWith(".bmp")) {
                filePath = filePath + "." + currentExtension;
            }

            console.log("使用文件复制方式保存: " + sourceFilePath + " 到 " + filePath);
            const result = fileStream.saveAs(sourceFilePath, filePath);
            if (result) {
                console.log("图片保存成功");
                _messageDialog.show("图片保存成功");
            } else {
                console.error("图片保存失败: " + fileStream.lastError());
                _messageDialog.show("保存失败: " + fileStream.lastError(), true);
            }
        }
    }

    FileDialog{
        id: _saveImageDialog
        title: "保存图片"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        nameFilters: ["PNG图像（*.png）","JPEG图像（*.jpg）"]
        // currentFolder:
        property var imageToSave: null

        onAccepted: {
            let filePath = selectedFile.toString()
            console.log("路径：",filePath)
            if(imageToSave){
                imageToSave.saveToFile(filePath)
                singlePlayer.croppedImageUrl = filePath
                singlePlayer.croppingFinished(filePath)
                console.log("图片已保存到：",filePath)
            }
        }
    }
}
