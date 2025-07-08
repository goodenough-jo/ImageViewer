import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Shapes
import QtQuick.Dialogs
import QtCore


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


    property rect deliver:Qt.rect(0,0,0,0)

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

        onPaint:{
            console.log("Canvas paint事件触发");

            // console.log("onPaint-图片状态(前)",image.status);
            //获取上下文并绘制
            const ctx = hiddenCanvas.getContext("2d");

            if (!ctx) {
                console.error("无法获取Canvas上下文");
                return;
            }

            console.log("开始绘制裁剪区域...");

            ctx.reset();

            console.log("drawImage启动")
            ctx.drawImage(image,
                          deliver.x, deliver.y, hiddenCanvas.width, hiddenCanvas.height,
                          0, 0, hiddenCanvas.width, hiddenCanvas.height);
            // console.log("onPaint-图片状态(后)",image.status);

            console.log("drawImage结束")
            console.log("Canvas paint事件结束")
        }
    }

    FileDialog{
        id:cropSaveDialog
        fileMode: FileDialog.SaveFile


        onAccepted: {
            var savePath = selectedFile.toString()
            cropImage(savePath)
        }
    }


    //只是计算出了裁剪区域，并没有实际裁剪图片
    function cropImage(savePath){
        console.log("开始裁剪操作...");

        console.log("源图片路径:", source.toString());
        console.log("保存路径:", savePath);
        console.log("图片状态:", image.status);
        console.log("裁剪区域:", cropArea);


        // 检查图片加载状态
        if (!image.isFullyLoaded) {
            console.error("图片未完全加载，当前状态:", image.status);
        }else{
            console.log("cropImage-图片完全加载",image.status)
        }

        /*
        if (image.status !== Image.Ready) {
            console.error("Image not ready for cropping");
            return;
        }
        */
        // console.log("图片状态（2）:", image.status);


        //获取图片实际显示区域
        //paintedWidth 或paintedHeight表示实际绘制图像的大小。在大多数情况下，它与width 和height 相同，但在使用Image.PreserveAspectFit 或Image.PreserveAspectCrop 时，paintedWidth 或paintedHeight 可以小于或大于图像项的width 和height 。
        const imgX = image.x + (image.width - image.paintedWidth) / 2       //图片实际显示区域的左上角在Image组件中的x坐标
        const imgY = image.y + (image.height - image.paintedHeight) / 2     //图片实际显示区域的左上角在Image组件中的y坐标
        const imgWidth = image.paintedWidth;                                //图片实际显示区域的宽度
        const imgHeight = image.paintedHeight;                              //图片实际显示区域的高度

        console.log("图片显示区域 - X:", imgX, "Y:", imgY, "宽度:", imgWidth, "高度:", imgHeight);



        //计算在图像实际显示区域中的裁剪区域(裁剪区域不超过图片区域)
        const cropInImage = Qt.rect(
                              Math.max(0,Math.min(imgWidth - 1,cropArea.x - imgX)),
                              Math.max(0,Math.min(imgHeight - 1,cropArea.y - imgY)),
                              Math.max(1,Math.min(imgWidth- (cropArea.x - imgX),cropArea.width)),
                              Math.max(1,Math.min(imgHeight - (cropArea.y - imgY),cropArea.height))
                            );

        console.log("图片坐标系中的裁剪区域:", cropInImage);



        //映射到原始图片坐标     比率=原始/实际    =》 原始 = 比率*实际
        const ratioX = image.sourceSize.width / imgWidth;
        const ratioY = image.sourceSize.height / imgHeight;

        // const sourceCrop = Qt.rect(
        //                      cropInImage.x * ratioX,
        //                      cropInImage.y * ratioY,
        //                      cropInImage.width * ratioX,
        //                      cropInImage.height * ratioY
        //                      );
        const sourceCrop = Qt.rect(
            Math.floor(cropInImage.x * ratioX),
            Math.floor(cropInImage.y * ratioY),
            Math.floor(cropInImage.width * ratioX),
            Math.floor(cropInImage.height * ratioY)
        );//修改浮点数为整数


        console.log("原始图片坐标系中的裁剪区域:", sourceCrop);

        deliver=sourceCrop;

        // 验证尺寸
        if (sourceCrop.width <= 0 || sourceCrop.height <= 0) {
            console.error("Invalid crop dimensions:", sourceCrop.width, sourceCrop.height);
            return;
        }

        hiddenCanvas.visible = true;

        // 设置Canvas尺寸（确保为整数）
        hiddenCanvas.width = Math.max(1, Math.floor(sourceCrop.width));
        hiddenCanvas.height = Math.max(1, Math.floor(sourceCrop.height));

        // hiddenCanvas.width = Math.max(1,sourceCrop.width);
        // hiddenCanvas.height = Math.max(1,sourceCrop.height);

        console.log("Canvas尺寸 - 宽度:", hiddenCanvas.width, "高度:", hiddenCanvas.height);


        // 添加Canvas绘制状态监听
        hiddenCanvas.onPaint.connect(function() {
            console.log("10. Canvas绘制完成回调触发");
        });


        hiddenCanvas.requestPaint();
        /*
        //获取上下文并绘制
        const ctx = hiddenCanvas.getContext("2d");

        if (!ctx) {
            console.error("无法获取Canvas上下文");
            return;
        }

        console.log("开始绘制裁剪区域...");

        ctx.reset();

        console.log("drawImage启动")
        ctx.drawImage(container.source,
                      sourceCrop.x, sourceCrop.y, hiddenCanvas.width, hiddenCanvas.height,
                      0, 0, hiddenCanvas.width, hiddenCanvas.height);
        console.log("drawImage结束")

        */

        //捕获图像
        hiddenCanvas.grabToImage(function(result){
            console.log("grabToImage启动")
            console.log("grabToImage-图片状态(前)",image.status);

            // if(result){
            //     console.log("开始保存")
            //     result.saveToFile("file:///root/crop.png")
            // }else{
            //     console.error("无法创建裁剪图像")
            //     container.croppingCancelled()
            // }

            if (!result) {
                console.error("无法创建裁剪图像");
                return;
            }

            console.log("开始保存裁剪后的图像...");
            result.saveToFile(savePath)
            console.log("grabToImage-图片状态(后)",image.status);

        },Qt.size(hiddenCanvas.width,  hiddenCanvas.height));

        // 退出裁剪模式（下次进入裁剪模式会重置裁剪范围）

        hiddenCanvas.visible = false;



        toggleCropMode();

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
            smooth: true    //缩放或拖拽时平滑过渡

            // 添加加载状态属性
            property bool isFullyLoaded: false

            onStatusChanged: {
                // console.log("Image.Ready:",Image.Ready)
                // console.log("Image.Loading:",Image.Loading)
                // console.log("Image.Error:",Image.Error)


                console.log("图片状态变化:", status);

                if (status === Image.Ready) {
                    console.log("image-图片已完全加载",image.status);
                    // console.log("Image.Ready:",Image.Ready)
                    isFullyLoaded = true;
                } else if (status === Image.Error) {
                    console.error("image-图片加载失败:",image.status);
                    // console.log("Image.Error:",Image.Error)

                    isFullyLoaded = false;
                } else if (status === Image.Loading){
                    console.log("image-图片正在加载",image.status)
                    // console.log("image-图片正在加载",Image.status);

                    isFullyLoaded = false;
                }
            }

            // 添加加载进度指示器
            BusyIndicator {
                anchors.centerIn: parent
                running: image.status === Image.Loading
                visible: running
            }

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
                // onClicked: cropImage()
                onClicked:{
                    var defaultName = "crop_"+Qt.formatDateTime(new Date(),"yyyyMMdd_hhmmss")

                    if(source.toString()){
                        defaultName +="_"+source.toString().split('/').pop()
                    }
                    // console.log("defualtName:"+defaultName)

                    cropSaveDialog.currentFile=StandardPaths.writableLocation(StandardPaths.PicturesLocation)
                                                    +"/"+defaultName

                    // console.log("cropSaveDialog.currentFile:"+cropSaveDialog.currentFile)
                    cropSaveDialog.open()

                }
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

