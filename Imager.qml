import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id:container
    anchors.fill: parent
    visible:false
    focus: visible

    // property alias rotationAngle:rotationAngle

    property url source
    property int rotationAngle : 0
    property real scaleFactor: 1.0      //缩放因子：现在尺寸=原来尺寸*缩放因子
    property real minScale: 0.1
    property real maxScale: 16.0
    property point imageOffset: Qt.point(0,0)       //图片相对父窗口的偏移量
    property point dragStart: Qt.point(0,0)         //拖拽起点
    property bool isDragging:false                  //是否正在拖拽

    //复原 todo！！！
    // onVisibleChanged: reset()
    // onSourceChanged: reset()

    Rectangle{
        id:bg
        anchors.fill: parent
        color: "white"
        opacity: 1      //不透明度  0.7蛮好看的

        TapHandler{
            onTapped: container.visible = false
        }
    }
    Item{
        id:imageContainer
        // anchors.centerIn: parent
        // anchors.fill: parent
        //修改定位方式：使用x,y定位代替centerIn
        x:(parent.width - width) / 2 + imageOffset.x    //newadd
        y:(parent.height -height) / 2 + imageOffset.y   //newadd
        width: Math.min(parent.width,parent.height) * scaleFactor
        height: width

        // scale: scaleFactor
        rotation: rotationAngle

        //transformOrigin 该属性包含缩放和旋转变化的原点，是枚举类型
        //自定义原点可用transform
        //todo 围绕鼠标位置进行缩放
        Image{
            id: image
            anchors.fill: parent     //将两个handler放入的时候需要注释此行
            source: container.source
            fillMode: Image.PreserveAspectFit   //图片自适应屏幕
            // fillMode: Image.PreserveAspectCrop   //图片自适应裁剪
            smooth: true    //缩放或拖拽时平滑过渡
            // antialiasing: true  //抗锯齿
            // scale: scaleFactor

        }

        WheelHandler{
            id: wheelHandler
            acceptedDevices: PointerDevice.Mouse

            acceptedModifiers: Qt.ControlModifier

            //缩放灵敏度
            property real zoomSensitivity: 0.5

            onWheel: (event) => {
                         if(event.modifiers & Qt.ControlModifier){
                             //计算缩放因子（基于滚轮旋转度数）
                             const zoomFactor = 1 +event.angleDelta.y * zoomSensitivity / 1200
                             scaleFactor = Math.max(minScale,Math.min(maxScale,zoomFactor))

                             // 尝试以鼠标位置为中心进行缩放，但是失败
                             // const containerPos = imageContainer.mapFromItem(null,event.x,event.y)
                             // const scaleRatio = newScale / scaleFactor
                             // imageOffset = Qt.point(
                             //     imageOffset.x +(containerPos.x - imageContainer.width / 2)*(1- 1/scaleRatio),
                             //     imageOffset.y +(containerPos.y - imageContainer.height / 2)*(1- 1/scaleRatio))

                             // imageContainer.x = (container.width-imageContainer.width) / 2 + imageOffset.x;
                             // imageContainer.y = (container.height-imageContainer.height) / 2 + imageOffset.y;

                             // imageContainer.scale = scaleFactor

                             imageContainer.width = Math.min(parent.width,parent.height) * scaleFactor
                             imageContainer.height= width
                         }
                     }
        }

        DragHandler{
            id:dragHandler
            // dragThreshold: 5    //该属性可设置拖拽阀值
            //acceptedDevices: PointerDevice.Mouse      //设置处理的设备，默认鼠标和触控屏的拖拽事件都能处理
            // acceptedButtons: Qt.RightButton          //设置接受处理的鼠标按键，默认为左键
            target: null

            //记录拖拽的起始位置
            onActiveChanged: {
                if(active){
                    dragStart = Qt.point(imageOffset.x,imageOffset.y)
                    isDragging = true
                }else{
                    isDragging = false
                }
            }

            //拖拽过程中更新位置
            onActiveTranslationChanged: {
                imageOffset = Qt.point(dragStart.x + activeTranslation.x,dragStart.y + activeTranslation.y)         //activeTranslation 记录拖拽时的平移量
            }
        }
    }

    function rotationClockwise(){
        rotationAngle = (rotationAngle + 90) % 360
    }

    function rotationCounterClockwise(){
        rotationAngle = (rotationAngle - 90 +360) % 360
    }

    function zoomIn(){
        if(scaleFactor<maxScale){
            scaleFactor += 0.1;
            if(scaleFactor>maxScale)
                scaleFactor = maxScale;
        }
    }

    function zoomOut(){
        if(scaleFactor>minScale){
            scaleFactor -= 0.1;
            if(scaleFactor<minScale)
                scaleFactor = minScale;
        }
    }
    //复原  todo！！！
    function reset(){
        imageContainer.scale = 1.0;
        // imageContainer.anchors.centerIn = parent
        // imageContainer.x = 100
        // imageContainer.y = 100
        // imageContainer.x = (container.width-imageContainer.width) / 2;
        // imageContainer.y = (container.height-imageContainer.height) / 2;
    }
}

// PinchHandler{
//     id: pinchhandler
//     target: iamgeContainer

//     //activeScale  执行捏合手势时的缩放因子
//     //activeRotation    执行捏合手势时的旋转角度



//     minimumScale: minScale
//     maximumScale: maxScale

//     property real startScale
//     onActiveChanged: if(active) startScale = scaleFactor

//     onScaleChanged: {
//         let newScale = startScale * pinchHandler.scale
//         scaleFactor = Math.max(minScale, Math.min(newScale, maxScale))
//     }

// }
