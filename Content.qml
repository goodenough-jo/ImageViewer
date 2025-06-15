import QtQuick

Item {
    property alias dialogs:_dialogs

    property ListModel musicFiles : ListModel{}//存储图片文件--filePath
    property int currentIndex : -1//索引
    property alias singlePlayer : _singlePlayer

    id:_content
    anchors.fill:parent
    GridView{
        id:gridView
        anchors.fill:parent

        model:musicFiles

        delegate: musicDelegate
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

