import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ExtraChain 1.0

import "."
import "Controls"
import "Fonts"

MouseArea {
    id: photoPreviewer
    visible: false
    anchors.fill: parent
    
    property int startY
    property int startX
    property real savedOpacity
    property string urlPhoto: ""
    property string idMessage
    property string message
    
    property bool gifMode: false
    onVisibleChanged: {
        if(!visible) {
            gifMode = false
            menu.visible = false
            background.opacity = visible ? 1.0 : background.opacity
        }
    }
    
    Rectangle {
        id: background
        anchors.fill: parent
        color: Colors.image_preview.background
    }
    
    Flickable {
        id: flick
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: height
        clip: true

        PinchArea {
            id: pinchArea
            width: Math.max(flick.contentWidth, flick.width)
            height: Math.max(flick.contentHeight, flick.height)

            property real initialWidth
            property real initialHeight
            pinch.minimumScale: 1.0
            pinch.maximumScale: 2.0

            onPinchStarted: {
                initialWidth = flick.contentWidth
                initialHeight = flick.contentHeight
            }

            onPinchUpdated: flick.resizeContent(initialWidth * pinch.scale, initialHeight * pinch.scale, pinch.center)

            onPinchFinished: {
                if (img.width < photoPreviewer.width) {
                    flick.resizeContent(photoPreviewer.width, photoPreviewer.height, pinch.center)
                }
                flick.returnToBounds()
            }

            Item {
                anchors.fill: parent
                anchors.margins: 20

                Image {
                    id: img
                    anchors.centerIn: parent
                    width: sourceSize.width < (parent.width - 20) ? sourceSize.width : (parent.width - 20)
                    property real _k: sourceSize.height / sourceSize.width
                    height: width * _k
                    source: photoPreviewer.urlPhoto
                    fillMode: Image.Pad
                    autoTransform: true
                    visible: !gifMode
                }

                AnimatedImage {
                    id: ai
                    anchors.centerIn: parent
                    width: sourceSize.width < (parent.width - 20) ? sourceSize.width : (parent.width - 20)
                    property real _k: sourceSize.height / sourceSize.width
                    height: width * _k
                    autoTransform: true
                    source: photoPreviewer.urlPhoto
                    fillMode: Image.Pad
                    visible: gifMode
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    width: 50
                    height: 50
                    running: true
                    antialiasing: true
                    visible: gifMode ? ai.status !== Image.Ready : img.status !== Image.Ready
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: {
            photoPreviewer.startY = mouseY
            photoPreviewer.startX = mouseX
            photoPreviewer.savedOpacity = background.opacity
        }
        
        onMouseYChanged: {
            var deltaY = mouseY - photoPreviewer.startY
            if (Math.abs(deltaY) >= height / 4) {
                photoPreviewer.closePreview()
                return
            }
            background.opacity = Math.max(0, photoPreviewer.savedOpacity - Math.abs(deltaY) / 400)
        }
        
        onReleased: {
            var deltaY = mouseY - photoPreviewer.startY
            if (deltaY >= height / 4) {
                photoPreviewer.closePreview()
            }
            background.opacity = 1.0
        }
        
        onClicked: photoPreviewer.closePreview()
    }
    
    SquareButton {
        anchors.right: parent.right
        width: 50
        height: width
        
        style: Colors.wallet_withdraw_page.button_back_style
        size: parent.width
        icon: IcoMoon.close
        
        onPressed: {
            console.log("clicked close")
            photoPreviewer.visible = false
        }
    }

    SquareButton {
        id: menuBtn
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 50
        height: width
        style: Colors.wallet_withdraw_page.button_back_style
        icon: IcoMoon.menu
        onClicked: {
            menu.visible = true
        }
    }

    Rectangle {
        id: menu
        property int parent_index: -1
        readonly property int _margin: 5
        readonly property int _h_icon: 30
        readonly property int _size_icon: 18
        anchors.right: parent.right
        anchors.bottom: menuBtn.top
        anchors.margins: 5

        width: max_width_text() + (2 * _margin) + _h_icon
        height: 80
        visible: false
        radius: 8
        color: Colors.image_preview.menu

        onVisibleChanged: {
            menu.width =  max_width_text() + (2 * _margin) + _h_icon
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                //first element menu
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: 16
                color: Colors.image_preview.menu
                opacity: copyMouseArea.containsMouse || !enabled ? 0.7 : 1.0
                enabled: !gifMode

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.radius
                    color: parent.color
                    enabled: !gifMode
                    opacity: copyMouseArea.pressed || !enabled ? 0.7 : 1.0
                }

                MouseArea {
                    id: copyMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !gifMode
                    onClicked: {
                        exportFileDialog.open()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: menu._margin
                        anchors.rightMargin: menu._margin
                        spacing: 0

                        Item {
                            Layout.preferredHeight: menu._h_icon
                            Layout.preferredWidth: menu._h_icon

                            IconText {
                                anchors.centerIn: parent
                                font.pixelSize: menu._size_icon
                                text: IcoMoon.copy
                                color: Colors.checkBox.text
                                opacity: copyMouseArea.pressed ? 0.7 : 1.0
                            }
                        }

                        MonserratText {
                            id: menu_copy_text
                            Layout.preferredHeight: parent.height
                            Layout.fillWidth: true
                            text: qsTr("Export file")
                            verticalAlignment: Text.AlignVCenter
                            color: Colors.detault_text_color
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 1
                Layout.fillWidth: true
                color: "white"
            }

            Rectangle {
                //last element menu
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: 16
                color: Colors.image_preview.menu
                opacity: deleteArea.containsMouse ? 0.7 : 1.0

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: parent.radius
                    color: parent.color
                    opacity: parent.opacity
                }

                MouseArea {
                    id: deleteArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("Begin_remove_message")
                        if(idMessage.length !== 0) {
                            messengerController?.removeMessage(idMessage)
                            photoPreviewer.visible = false
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: menu._margin
                        anchors.rightMargin: menu._margin
                        spacing: 0

                        Item {
                            Layout.preferredHeight: menu._h_icon
                            Layout.preferredWidth: menu._h_icon

                            IconText {
                                anchors.centerIn: parent
                                font.pixelSize: menu._size_icon
                                text: IcoMoon.trash
                                color: Colors.red
                                opacity: deleteArea.pressed ? 0.7 : 1.0
                            }
                        }

                        MonserratText {
                            id: menu_delete_text
                            Layout.preferredHeight: parent.height
                            Layout.fillWidth: true
                            text: qsTr("Delete")
                            verticalAlignment: Text.AlignVCenter
                            color: Colors.red
                        }
                    }
                }
            }
        }

        FileDialog {
            id: exportFileDialog
            title: "Select a folder for export file"
            fileMode: FileDialog.Directory
            onAccepted: {
                var folderUrl = exportFileDialog.selectedFiles[0]
                var folderPath = folderUrl.toString().replace("file://", "")
                console.log("Selected folder:", folderPath)
                let path = folderPath.substring(0, folderPath.lastIndexOf("/"))
                console.log("Parent folder:", path)
                messengerController?.exportFile(message, path)
                menu.visible = false
            }
        }

        function max_width_text() {
            var res = menu_copy_text.paintedWidth;
            if(menu_delete_text.paintedWidth > res)
                res = menu_delete_text.paintedWidth
            return res + (2 * _margin) + _h_icon
        }
    }


    
    function closePreview() {
        photoPreviewer.visible = false
        photoPreviewer.urlPhoto = ""
        background.opacity = 1.0
    }
}
