import QtQuick
import QtQuick.Controls

Item {
    property alias open: _open
    property alias view:_view
    property alias see:_see
    property alias next:_next
    property alias previous :_previous
    property alias tool:_tool

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



}
