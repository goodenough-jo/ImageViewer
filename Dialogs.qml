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
            messageDialog.text = text;
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
                text:originalName.split(".")[0]
                selectByMouse: true
                focus:true
            }
        }
        //封装有问题需要优化
        onAccepted:{
            if (namefield.text === "") return;
            const result = fileStream.renameFile(filePath, namefield.text);
            if (!result) {
                messageDialog.show("重命名失败: " + fileStream.lastError(), true);
            }
        }
    }
    InfoPopup{
        id:_infoPopup
    }

}
