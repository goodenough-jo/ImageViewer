import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Shapes


Item {
    id:container
    anchors.fill: parent
    visible:false
    focus: visible

    property url source
    property int rotationAngle : 0
    property real scaleFactor: 1.0      //缩放因子：现在尺寸=原来尺寸*缩放因子
    property real minScale: 0.1
    property real maxScale: 16.0
    property point imageOffset: Qt.point(0,0)       //图片相对父窗口的偏移量
    property point dragStart: Qt.point(0,0)         //拖拽起点
    property bool isDragging:false                  //是否正在拖拽
    property bool horizontalFlip: false
    property bool verticalFlip: false
    property real initialHeight: 500
    property real initialWidth: 500

    property bool isFullscreen:false
    property bool cropMode: false       //判断是否进入裁剪模式
    property rect cropArea: Qt.rect(0,0,0,0)
    property point cropStartPoint: Qt.point(0,0)
    property point cropDragPoint: Qt.point(0,0)
    property int activeCornner: -1      //-1:无活动角， 0:左上， 1:右上，2:右下， 3:左下角
    property bool isCropDragging: false
    property real aspectRatio: 0        //0表示自由比例

    property url croppedImageUrl:""
    signal croppingFinished(url imageUrl)
    signal croppingCancelled()

    //切换裁剪模式
    function toggleCropMode(){
        cropMode = !cropMode;
        if(cropMode){
            //初始化裁剪区域

            cropArea = Qt.rect(
                        imageContainer.width * 0.25,
                        imageContainer.height * 0.25,
                        imageContainer.width * 0.5,
                        imageContainer.height * 0.5
            );

            aspectRatio = 0;        //重置为自由比例
        }
    }

    Canvas{
        id: hiddenCanvas
        visible: false
    }

    //只是计算出了裁剪区域，并没有实际裁剪图片
    function cropImage(){
        console.log("source:"+source.toString())

        if (image.status !== Image.Ready) {
            console.error("Image not ready for cropping");
            return;
        }

        //获取图片实际显示区域
        //paintedWidth 或paintedHeight表示实际绘制图像的大小。在大多数情况下，它与width 和height 相同，但在使用Image.PreserveAspectFit 或Image.PreserveAspectCrop 时，paintedWidth 或paintedHeight 可以小于或大于图像项的width 和height 。
        const imgX = image.x + (image.width - image.paintedWidth) / 2       //图片实际显示区域的左上角在Image组件中的x坐标
        const imgY = image.y + (image.height - image.paintedHeight) / 2     //图片实际显示区域的左上角在Image组件中的y坐标
        const imgWidth = image.paintedWidth;                                //图片实际显示区域的宽度
        const imgHeight = image.paintedHeight;                              //图片实际显示区域的高度

        //计算在图像实际显示区域中的裁剪区域(裁剪区域不超过图片区域)
        const cropInImage = Qt.rect(
                              Math.max(0,Math.min(imgWidth - 1,cropArea.x - imgX)),
                              Math.max(0,Math.min(imgHeight - 1,cropArea.y - imgY)),
                              Math.max(1,Math.min(imgWidth- (cropArea.x - imgX),cropArea.width)),
                              Math.max(1,Math.min(imgHeight - (cropArea.y - imgY),cropArea.height))
                            );

        //映射到原始图片坐标     比率=原始/实际    =》 原始 = 比率*实际
        const ratioX = image.sourceSize.width / imgWidth;
        const ratioY = image.sourceSize.height / imgHeight;

        const sourceCrop = Qt.rect(
                             cropInImage.x * ratioX,
                             cropInImage.y * ratioY,
                             cropInImage.width * ratioX,
                             cropInImage.height * ratioY
                             );


        //打印scourceCrop坐标
        console.log("sourceCrop.x:"+sourceCrop.x)
        console.log("sourceCrop.y:"+sourceCrop.y)
        console.log("sourceCrop.width:"+sourceCrop.width)
        console.log("sourceCrop.height:"+sourceCrop.height)


        // 验证尺寸
        if (sourceCrop.width <= 0 || sourceCrop.height <= 0) {
            console.error("Invalid crop dimensions:", sourceCrop.width, sourceCrop.height);
            return;
        }


        hiddenCanvas.width = Math.max(1,sourceCrop.width);
        hiddenCanvas.height = Math.max(1,sourceCrop.height);

        //打印hiddenCanvas的坐标
        console.log("hiddenCanvas.x:"+hiddenCanvas.x)
        console.log("hiddenCanvas.y:"+hiddenCanvas.y)
        console.log("hiddenCanvas.width:"+hiddenCanvas.width)
        console.log("hiddenCanvas.height:"+hiddenCanvas.height)


        //获取上下文并绘制
        const ctx = hiddenCanvas.getContext("2d");
        ctx.reset();
        ctx.drawImage(container.source,
                      sourceCrop.x, sourceCrop.y, sourceCrop.width, sourceCrop.height,
                      0, 0, hiddenCanvas.width, hiddenCanvas.height);

        //捕获图像
        hiddenCanvas.grabToImage(function(result){

            if(result){
                // //设置要保存的图像并打开对话框
                // dialogs.saveDialog.imageToSave = result
                // dialogs.saveDialog.open()
                result.saveToFile("file:///root/crop.png")
            }else{
                console.error("无法创建裁剪图像")
                container.croppingCancelled()
            }
        },Qt.size(sourceCrop.width, sourceCrop.height));

        // 退出裁剪模式（下次进入裁剪模式会重置裁剪范围）
        toggleCropMode();

        // 推出裁剪模式（下次进入裁剪模式时仍然是上次的裁剪框大小和位置）
        // cropMode = !cropMode;
    }

    //固定比例裁剪
    function setAspectRatio(ratio){
        aspectRatio = ratio;
        if(ratio <= 0) return;

        const currentArea = container.cropArea;
        const centerX = currentArea.x + currentArea.width / 2;
        const centerY = currentArea.y + currentArea.height / 2;

        let newWidth, newHeight;
        if(currentArea.width / currentArea.height > ratio){
            newWidth = currentArea.width;
            newHeight = newWidth * ratio;
        }else{
            newWidth = currentArea.width;
            newHeight = newWidth / ratio;
        }

        container.cropArea = Qt.rect(
                    centerX - newWidth / 2,
                    centerY - newHeight / 2,
                    newWidth,
                    newHeight
                );
    }

    //复原
    onVisibleChanged: reset()
    onSourceChanged: reset()

    Rectangle{
        id:bg
        anchors.fill: parent
        color: "white"
        opacity: 1      //不透明度  0.7蛮好看的

        TapHandler{
            // onTapped: container.visible = false
            onTapped: {
                if (!isFullscreen) {
                    container.visible = false
                }
            }//修改：在全屏下禁止返回多图浏览
        }
    }
    Item{
        id:imageContainer
        // anchors.centerIn: parent
        // anchors.fill: parent
        //修改定位方式：使用x,y定位代替centerIn
        x:(parent.width - width) / 2 + imageOffset.x
        y:(parent.height -height) / 2 + imageOffset.y

        //可以设置一个全局变量来复制初始宽高
        height: initialHeight
        width: initialWidth
        // height: width
        // width: Math.min(parent.width,parent.height) * scaleFactor

        scale: scaleFactor
        rotation: rotationAngle

        //镜像翻转
        transform:[
            Scale{
                origin.x: imageContainer.width / 2
                origin.y:imageContainer.height / 2
                xScale: horizontalFlip ? -1 : 1
                yScale: verticalFlip ? -1 : 1
            }
        ]

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
                             // const zoomFactor = 1 +event.angleDelta.y * zoomSensitivity / 1200
                             const zoomFactor = event.angleDelta.y * zoomSensitivity / 1200
                             scaleFactor = Math.max(minScale,Math.min(maxScale,zoomFactor+scaleFactor))

                         }
                     }
        }

        DragHandler{
            id:dragHandler

            target: null

            enabled: !container.cropMode        //newadd: 裁剪时禁止拖拽

            property point tempOffset: Qt.point(0,0)

            //记录拖拽的起始位置
            onActiveChanged: {
                if(active && !container.cropMode){      //newadd
                    dragStart = Qt.point(imageOffset.x,imageOffset.y)
                    tempOffset = dragStart
                    isDragging = true
                }else{
                    isDragging = false
                }
            }

            //拖拽过程中更新位置
            onActiveTranslationChanged: {
                if(!container.cropMode){        //newadd
                    tempOffset = Qt.point(dragStart.x + activeTranslation.x,dragStart.y + activeTranslation.y)  //activeTranslation 记录拖拽时的平移量
                    imageOffset = Qt.binding(function(){
                        return Qt.point(tempOffset.x,tempOffset.y)
                    })

                }

            }
        }
    }

    //裁剪层
    Item{
        id: cropOverlay
        anchors.fill: parent
        visible: container.cropMode

        //半透明罩
        Rectangle{
            anchors.fill: parent
            color: "black"
            opacity: 0.4

            //使用shape创建挖空效果（图片保留的内容)        ??????
            Shape{
                anchors.fill: parent
                ShapePath{
                    fillColor: "black"
                    fillRule: ShapePath.OddEvenFill
                    PathRectangle{x: 0; y: 0; width: parent.width; height: parent.height }
                    PathRectangle{
                        x: container.cropArea.x
                        y: container.cropArea.y
                        width: container.cropArea.width
                        height: container.cropArea.height
                    }
                }
            }
        }

        //裁剪框
        Item{
            id: cropFrame
            x: container.cropArea.x
            y: container.cropArea.y
            width: container.cropArea.width
            height: container.cropArea.height

            //边框
            Rectangle{
                anchors.fill: parent
                color: "transparent"
                border.color: "white"
                border.width: 1.5
            }

            //半透明内框
            Rectangle{
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.color: "#40000000"
                border.width: 1
            }

            //Repeater 类型用于创建大量类似的项目。与其他视图类型一样，Repeater 也有一个model 和一个delegate
            Repeater{
                model: 4
                delegate: Rectangle{
                    width: 16;
                    height: 16;
                    color: "white"
                    border.width: 1
                    border.color: "#80000000"

                    //计算位置
                    function getPosition(){
                        switch(index){
                        case 0: return Qt.point(0,0);   //左上
                        case 1: return Qt.point(parent.width - width, 0);   //右上
                        case 2: return Qt.point(parent.width - width, parent.height - height);  //右下
                        case 3: return Qt.point(0,parent.height - height);  //左下
                        default: return Qt.point(0,0);
                        }
                    }

                    x: getPosition().x
                    y: getPosition().y

                    //点处理器
                    PointHandler{
                        id: cornerHandler
                        acceptedDevices: PointerDevice.AllDevices
                        cursorShape: {
                            switch(index){
                            case 0: return Qt.SizeFDiagCursor;
                            case 1: return Qt.SizeBDiagCursor;
                            case 2: return Qt.SizeFDiagCursor;
                            case 3: return Qt.SizeBDiagCursor;
                            default: return Qt.ArrowCursor;
                            }
                        }

                        onPointChanged: {
                            if(active){
                                container.activeCornner = index;
                                const pointInOverlay = cornerHandler.point.position;
                                const overlayPoint = cropOverlay.mapFromItem(cornerHandler.target, pointInOverlay.x, pointInOverlay.y)

                                updateCornerPosition(overlayPoint);
                            }
                        }

                        onActiveChanged: {
                            if(!active){
                                container.activeCornner = -1;
                            }
                        }
                    }

                    function updateCornerPosition(point){
                        const minSize = 30;

                        let newX = container.cropArea.x;
                        let newY = container.cropArea.y;
                        let newWidth = container.cropArea.width;
                        let newHeight = container.cropArea.height;

                        switch(container.activeCornner){
                        case 0://左上角
                            if(aspectRatio > 0){
                                const deltaX = container.cropArea.x - point.x;
                                const deltaY = container.cropArea.y - point.y;
                                const delta = aspectRatio > 1 ? deltaX : deltaY * aspectRatio;

                                newX = Math.max(0, point.x);
                                newY = container.cropArea.y - delta / aspectRatio;
                                newWidth = Math.max(minSize, container.cropArea.width + (container.cropArea.x - newX));
                                newHeight = Math.max(minSize, container.cropArea.height + (container.cropArea.y - newY));
                            }else{
                                newX = Math.max(0, Math.min(newX + newWidth - minSize, point.x));
                                newY = Math.max(0, Math.min(newY + newHeight - minSize, point.y));
                                newWidth = Math.max(minSize, container.cropArea.x + container.cropArea.width - newX);
                                newHeight = Math.max(minSize, container.cropArea.y + container.cropArea.height - newY);
                            }
                            break;
                        case 1://右上角
                            newY = Math.max(0, Math.min(newY + newHeight - minSize, point.y));
                            newWidth = Math.max(minSize, Math.min(cropOverlay.width - newX, point.x - newX));

                            if (aspectRatio > 0) {
                                newHeight = newWidth / aspectRatio;
                            } else {
                                newHeight = Math.max(minSize, container.cropArea.y + container.cropArea.height - newY);
                            }
                            break;
                        case 2:
                            newWidth = Math.max(minSize, Math.min(cropOverlay.width - newX, point.x - newX));

                            if(aspectRatio > 0){
                                newHeight = newWidth / aspectRatio;
                            }else{
                                newHeight = Math.max(minSize, Math.min(cropOverlay.height - newY, point.y - newY));
                            }
                            break;
                        case 3:
                            newX = Math.max(0, Math.min(newX + newWidth - minSize, point.x));
                            newWidth = Math.max(minSize, container.cropArea.x + container.cropArea.width - newX);

                            if(aspectRatio > 0){
                                newHeight = newWidth / aspectRatio;
                            }else{
                                newHeight = Math.max(minSize, Math.min(cropOverlay.height - newY, point.y - newY));
                            }
                            break;
                        }

                        container.cropArea = Qt.rect(newX, newY, newWidth, newHeight);
                    }
                }
            }

            DragHandler{
                id: frameDragHandler
                target: null
                acceptedDevices: PointerDevice.AllDevices
                cursorShape: Qt.SizeAllCursor

                property point startPosition: Qt.point(0,0)

                onActiveChanged: {
                    if(active){
                        startPosition = Qt.point(container.cropArea.x, container.cropArea.y);
                    }else{
                        container.isCropDragging = false;
                    }
                }

                onTranslationChanged: {
                    const dx = translation.x;
                    const dy = translation.y;

                    const boundedX = Math.max(0,Math.min(
                                                  cropOverlay.width - container.cropArea.width,
                                                  startPosition.x + dx
                                                  ));

                    const boundedY = Math.max(0,Math.min(
                                                  cropOverlay.height - container.cropArea.height,
                                                  startPosition.y + dy
                                                  ));

                    container.cropArea = Qt.rect(
                                boundedX,
                                boundedY,
                                container.cropArea.width,
                                container.cropArea.height
                                );
                }
            }
        }
    }


    //todo:  裁剪控件布局
    Rectangle {
        id: cropControlBar
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: 20
        }
        width: Math.min(parent.width - 40, 500)
        height: 60
        color: "#E6121212"
        radius: 8
        visible: cropMode
        opacity: 0.95

        // 控制按钮布局
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // 比例选择按钮
            Button {
                Layout.preferredWidth: 90
                text: "自由比例"
                checked: aspectRatio === 0
                checkable: true
                onClicked: setAspectRatio(0)
            }

            Button {
                Layout.preferredWidth: 70
                text: "1:1"
                checked: aspectRatio === 1
                checkable: true
                onClicked: setAspectRatio(1)
            }

            Button {
                Layout.preferredWidth: 70
                text: "4:3"
                checked: aspectRatio === 4/3
                checkable: true
                onClicked: setAspectRatio(4/3)
            }

            Button {
                Layout.preferredWidth: 70
                text: "16:9"
                checked: aspectRatio === 16/9
                checkable: true
                onClicked: setAspectRatio(16/9)
            }

            Item { Layout.fillWidth: true }

            // 控制按钮
            Button {
                text: "取消"
                Layout.preferredWidth: 80
                onClicked: toggleCropMode()
            }

            Button {
                text: "裁剪"
                Layout.preferredWidth: 80
                highlighted: true
                onClicked: cropImage()
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

    function flipHorizontally(){
        horizontalFlip = !horizontalFlip
    }

    function flipVertically(){
        verticalFlip = !verticalFlip
    }

    //复原
    function reset(){
        rotationAngle = 0
        scaleFactor = 1.0
        imageOffset = Qt.point(0,0)
        horizontalFlip = false
        verticalFlip =false
        cropMode = false
    }

}

