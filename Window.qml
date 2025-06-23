import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    //全屏
    property bool isFullscreen : false
    //幻灯片播放
    property bool isSlideshowPlaying: false
    property int slideshowInterval: 2000 // 默认2秒切换一次

    width: 900;height: 700;visible: true
    title:"图片浏览器"


    header: ToolBar{
        RowLayout{
            ToolButton{action:actions.open}
            // ToolButton{action:actions.del}  //删除按钮移到左侧工具栏
            // ToolButton{action:actions.rename}   //重命名按钮移到左侧工具栏
            // ToolButton{action:actions.info} //信息按钮移到左侧工具栏
            ToolSeparator{Layout.fillHeight: true}
            ToolButton{action:actions.view}
            ToolButton{action:actions.see}
            ToolSeparator{Layout.fillHeight: true}
            ToolButton{action:actions.previous}
            ToolButton{action:actions.next}
            // ToolButton{action:actions.tool}

            ToolButton{action:actions.fullscreen}//全屏
            ToolButton{action:actions.slidershow}//幻灯片播放
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

        del.onTriggered: {
            var filePath = content.singlePlayer.source.toString().replace("file://","")
            content.dialogs.confirmDialog.confirm(filePath)
        }//delete按钮

        rename.onTriggered: {
            var filePath = content.singlePlayer.source.toString().replace("file://","")
            content.dialogs.renameDialog.rename(filePath)
        }//rename按钮
        
        info.onTriggered: {
            var filePath = content.singlePlayer.source.toString()
            content.dialogs.infoPopup.showInfo(filePath)
        }//info按钮

        rotateCCW.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.rotationCounterClockwise()
            }
        }//逆时针旋转

        rotateCW.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.rotationClockwise()
            }
        }//顺时针旋转

        zoomIn.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.zoomIn()
            }
        }//放大

        zoomOut.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.zoomOut()
            }
        }//缩小

        horizontalFlip.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.flipHorizontally()
            }
        }//水平翻转

        verticalFlip.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.flipVertically()
            }
        }//垂直翻转


        // 全屏按钮事件处理
        fullscreen.onTriggered: {
            if(content.singlePlayer.visible){
                isFullscreen = !isFullscreen
                content.singlePlayer.isFullscreen = isFullscreen  // 同步全屏状态
                if(isFullscreen) {
                    visibility = Window.FullScreen
                    // header.visible=false   //隐藏顶部工具栏
                    content.leftPage.visible = false  // 隐藏左侧工具栏
                } else {
                    visibility = Window.Windowed
                    content.singlePlayer.reset()   //调用寇灿的还原函数
                    header.visible=true   //隐藏顶部工具栏
                    content.leftPage.visible = true   // 显示左侧工具栏
                }
            }
        }

        // 在 Actions 的绑定中添加幻灯片播放功能
        slidershow.onTriggered: {
            if(content.musicFiles.count === 0) return;

            isSlideshowPlaying = !isSlideshowPlaying

            if(isSlideshowPlaying) {
                // 确保单图查看模式
                if(!content.singlePlayer.visible) {
                    content.singlePlayer.source = content.musicFiles.get(content.currentIndex).filePath
                    content.singlePlayer.visible = true
                }
                slideshowTimer.start()  //自带方法
            } else {
                slideshowTimer.stop()   //自带方法
            }
        }


        crop.onTriggered: {
            if(content.singlePlayer.visible){
                content.singlePlayer.crop()
            }
        }//裁剪
    }

    Content{
        id:content
    }




    // 添加计时器
    Timer {
        id: slideshowTimer
        interval: slideshowInterval   //间隔时间
        repeat: true
        onTriggered: {
            if(content.currentIndex < content.musicFiles.count - 1) {
                content.currentIndex++
            } else {
                content.currentIndex = 0 // 循环播放
            }
            content.singlePlayer.source = content.musicFiles.get(content.currentIndex).filePath
        }
    }


}
