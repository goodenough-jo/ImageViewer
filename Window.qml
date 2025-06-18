import QtQuick
import QtQuick.Controls
import QtQuick.Layouts



ApplicationWindow {
    width: 1000;height: 700;visible: true

    header: ToolBar{
        RowLayout{
            ToolButton{action:actions.open}
            ToolSeparator{Layout.fillHeight: true}
            ToolButton{action:actions.view}
            ToolButton{action:actions.see}
            ToolSeparator{Layout.fillHeight: true}
            ToolButton{action:actions.previous}
            ToolButton{action:actions.next}
            ToolButton{action:actions.tool}
        }
    }

    Actions{
        id:actions
        open.onTriggered: content.dialogs.openDialog.open()

        view.onTriggered: content.singlePlayer.visible=false//多图查看

        see.onTriggered: {
            content.singlePlayer.focus=true//设置焦点，保证左右键运行
            content.singlePlayer.source=content.musicFiles.get(content.currentIndex).filePath
            content.singlePlayer.visible=true
        }//单图查看

        previous.onTriggered: {
            // console.log("musicFile:"+content.musicFiles.count)
            // console.log("currentIndex:"+content.currentIndex)
            if(content.currentIndex > 0) {
                content.currentIndex--;
                content.singlePlayer.source = content.musicFiles.get(content.currentIndex).filePath;
                content.singlePlayer.visible = true;
            }
        }//previous按钮

        next.onTriggered: {
            // console.log("musicFile:"+content.musicFiles.count)
            // console.log("currentIndex:"+content.currentIndex)

            if(content.currentIndex < content.musicFiles.count - 1) {
                content.currentIndex++;
                content.singlePlayer.source = content.musicFiles.get(content.currentIndex).filePath;
                content.singlePlayer.visible = true;
            }
        }//next按钮



    }

    Content{
        id:content
    }
}

