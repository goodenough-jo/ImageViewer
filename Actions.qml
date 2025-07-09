import QtQuick
import QtQuick.Controls

Item {
    property alias open: _open
    property alias view:_view
    property alias see:_see
    property alias next:_next
    property alias previous :_previous
    property alias del:_delete
    property alias rename:_rename
    property alias info:_info
    property alias rotateCCW: _rotationCCW
    property alias rotateCW: _rotationCW
    property alias zoomIn: _zoomIn
    property alias zoomOut: _zoomOut
    property alias saveAs: _save
    property alias horizontalFlip: _horizontalFlip
    property alias verticalFlip: _verticalFlip
    property alias crop: _crop
    property alias fullscreen:_fullscreen//全屏
    property alias slidershow:_slideshow
    // property alias folderView: _folderView // 添加文件夹视图属性

    Action{
        id:_open
        text: "open"
        icon.name:"document-open"
    }//后面删除

    Action{
        id:_view
        text:"view"
        icon.name:"view-grid"
    }
    Action{
        id:_see
        text:"see"
        icon.name:"document-preview"
    }

    Action{
       id:_next
       // text:"next"
       icon.name:"go-next"
    }
    Action{
        id:_previous
        // text: "previous"
        icon.name:"go-previous"
    }

    // Action{
    //     id:_tool
    //     text:"tool"
    //     icon.name:"document-properties"
    // }

    Action{
        id:_delete
        text:"remove"
        icon.name:"edit-delete"
    }
    Action{
        id:_rename
        text:"Rename"
        icon.name:"accessories-text-editor"
    }
    Action{

        id:_info
        text:"Information"
        icon.name:"dialog-information"
    }
    Action{
        id:_rotationCW
        text:"Rotate CW"
        icon.name: "object-rotate-right"
    }//顺时针
    Action{
        id:_rotationCCW
        text:"Rotate CCW"
        icon.name: "object-rotate-left"
    }//逆时针
    Action{
        id:_zoomIn
        text:"Zoom In"
        icon.name:"zoom-in"
    }//放大
    Action{
        id:_zoomOut
        text:"Zoom Out"
        icon.name:"zoom-out"
    }//缩小
    Action{
        id:_save
        text:"Save As"
        icon.name:"document-save-as"
    }//保存
    Action{
        id:_horizontalFlip
        text:"Horizontal Flip"
        icon.name: "object-flip-horizontal"
    }//水平翻转
    Action{
        id:_verticalFlip
        text:"Vertical Flip"
        icon.name: "object-flip-vertical"
    }//垂直翻转


    Action{
        id:_fullscreen
        text:"Fullscreen"
        icon.name:"view-fullscreen"
    }//全屏按钮

    Action {
        id: _slideshow
        text: "Slideshow"
        icon.name: "media-playback-start"
    }//幻灯片播放
    Action{
        id:_crop
        text: "Crop"
        icon.name: "edit-cut"
    }//裁剪
    
    // Action{
    //     id: _folderView
    //     text: "Folder View"
    //     icon.name: "folder-pictures"
    // }//文件夹图片视图
}
