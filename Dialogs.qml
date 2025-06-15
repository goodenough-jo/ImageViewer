import QtQuick
import QtQuick.Dialogs

Item {
    property alias openDialog:_openDialog

    FileDialog{
        id:_openDialog
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Select images (*.jpg)"]
    }
}
