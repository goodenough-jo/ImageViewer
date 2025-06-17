import QtQuick
import QtQuick.Dialogs
import Qt.labs.folderlistmodel

Item {
    property alias dialogs:_dialogs

    property ListModel musicFiles : ListModel{}//存储图片文件--filePath
    property int currentIndex : -1//索引
    property alias singlePlayer : _singlePlayer
    property alias gridView:_multiPic

    id:_content
    anchors.fill:parent
    GridView{
        id:_multiPic
        anchors.fill:parent
        model:musicFiles
        delegate: musicDelegate

        Connections{
            target: fileStream
            function onFileRemoved(path)
            {
                console.log("File removed signal received: " + path)
                
                // Remove file from model if it exists
                for(let i = 0; i < musicFiles.count; i++) {
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
                        
                        // Hide player if current file was deleted
                        if(singlePlayer.source.toString().replace("file://", "") === path) {
                            singlePlayer.visible = false
                            console.log("Hiding single player view")
                            
                            if(musicFiles.count > 0) {
                                singlePlayer.source = musicFiles.get(currentIndex).filePath
                                console.log("Updated player source to: " + musicFiles.get(currentIndex).filePath)
                            } else {
                                singlePlayer.source = ""
                                console.log("Cleared player source")
                            }
                        }
                        break;
                    }
                }
            }
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
            
            // Set the first image as default
            if(musicFiles.count > 0) {
                singlePlayer.source = musicFiles.get(0).filePath
                console.log("Set default image path: " + musicFiles.get(0).filePath)
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

