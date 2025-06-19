import QtQuick
import QtQuick.Controls

Item {
    property alias open: _open
    property alias view:_view
    property alias see:_see
    property alias next:_next
    property alias previous :_previous
    property alias tool:_tool
    property alias del:_delete
    property alias rename:_rename
    property alias info:_info
    property alias rotateCCW: _rotationCCW
    property alias rotateCW: _rotationCW
    property alias zoomIn: _zoomIn
    property alias zoomOut: _zoomOut

    Action{
        id:_open
        text: "open"
        icon.name:"document-open"
    }//后面删除

    Action{
        id:_view
        text:"view"
        icon.name:"document-properties"
    }
    Action{
        id:_see
        text:"see"
        icon.name:"document-properties"
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
    Action{
        id:_tool
        text:"tool"
        icon.name:"document-properties"
    }
    Action{
        id:_delete
        text:"remove"
        icon.name:"edit-delete"
    }
    Action{
        id:_rename
        text:"Rename"
    }
    Action{

        id:_info
        text:"Information"
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

}
