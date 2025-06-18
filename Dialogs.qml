import QtQuick
import QtQuick.Dialogs
import QtQuick.Controls

Item {
    property alias openDialog: _openDialog
    property alias messageDialog: _messageDialog
    property alias confirmDialog: _confirmDialog

    FileDialog{
        id: _openDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Select images (*.jpg)"]
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
}
