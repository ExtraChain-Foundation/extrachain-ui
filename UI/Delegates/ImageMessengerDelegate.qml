import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"

Item {
    id: imageDelegate
    height: cl.implicitHeight
    property int maxWidth
    property int minWidth: hasCaption && caption.length > 0 ? (captionText.paintedWidth + 20) : 50
    property bool isShowDateSeparator: false
    property bool hasReplyAnswer: false
    property int replyType: MessegeDelegateType.Text
    property string replyMessage
    property bool blurHashState: true
    property string parentMessageId
    property bool hasCaption: false
    property string caption

    Component.onCompleted: {
        console.log("caption:", caption, hasCaption, caption.length)
    }

    Connections {
        target: messengerController

        function onRunAnimation(delegate_index) {
            if(index === delegate_index) {
                colorFlashAnimation.restart()
            }
        }
    }
    
    ColumnLayout {
        id: cl
        anchors.fill: parent
        Layout.maximumHeight: 500
        spacing: 5
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: imageDelegate.isShowDateSeparator ? 24 : 0
            Layout.preferredWidth: daySeparateTextForImage.paintedWidth + 16
            color: Colors.messenger.day_separator
            radius: height/2
            
            MonserratText {
                id: daySeparateTextForImage
                visible: imageDelegate.isShowDateSeparator ? true : false
                anchors.centerIn: parent
                text: new Date(timestamp).toLocaleDateString()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: Colors.messenger.day_separator_text
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.minimumWidth: imageDelegate.minWidth
                visible: owner
            }
            
            Rectangle {
                id: imageBox
                property real scaleFactor: Math.min(1, Math.min(500 / (image.blur_height + 10), maxWidth / image.blur_width))
                Layout.preferredWidth: (captionText.paintedWidth > ((image.blur_width * scaleFactor) + 20))
                                        ? captionText.paintedWidth > maxWidth ? maxWidth
                                        : captionText.paintedWidth
                                        : ((image.blur_width * scaleFactor) + 20)
                Layout.preferredHeight: clInner.implicitHeight + 10
                Layout.minimumWidth: minWidth + 20
                Layout.minimumHeight: minWidth + 10

                Component.onCompleted: {
                    if(hasCaption) {
                        console.log("csdcmsdmcdscmdsmc", captionText.paintedWidth, (image.blur_width * scaleFactor), maxWidth, imageBox.width)
                    }
                }

                color: owner ? Colors.messenger.background_receiver : Colors.messenger.background_sender
                radius: 10
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: owner ? undefined : parent.left
                    anchors.right: owner ? parent.right : undefined
                    radius: 3
                    width: 20
                    height: 20
                    color: parent.color
                }

                FlashAnimation {
                    id: colorFlashAnimation
                    color_in: imageBox.color
                    _target: imageBox
                }

                MouseArea {
                    id: mouseMenuImage
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    propagateComposedEvents: true
                    z: -1

                    onPressAndHold: {
                        if(!root.isMobile)
                            return;
                        hideMenu()
                        var point = image.mapToItem(messengerRoot, 0, 0)
                        console.log(point)

                        menu.x = point.x + gifBox.width - menu.width
                        if(point.y >= menu.height)
                            menu.y = point.y - menu.height - 2
                        else
                            menu.y = point.y + gifBox.height
                        menu.type = MessegeDelegateType.Image
                        menu.message = messageText.text
                        menu.messageId = messageId
                        chatItem.grabToImage(function(result) {
                            if (result) {
                                screenshotImage.source =  result.url
                                blurEffect.source = screenshotImage
                                screenshotImage.visible = true
                                var p = messageDelegate.mapToItem(chatItem, 0, 0)
                                dublicateMessageRect.width = gifBox.width
                                dublicateMessageRect.height = gifBox.height
                                dublicateMessageRect.x = point.x
                                if(point.y >= menu.height)
                                    dublicateMessageRect.y = menu.y + menu.height + 2
                                else
                                    dublicateMessageRect.y = point.y
                                dublicateMessageRect.color = messageBox.color
                                dublicateMessageRect.radius = messageBox.radius
                                messageDublicateText.text = messageText.text
                                messageDublicateText.textFormat = messageText.textFormat
                                dublicateTimeText.text = timeText.text
                                chatItem.visible = false
                                blurItem.visible = true
                                console.log("screenshot visible", screenshotImage.visible)
                            }
                        })

                        menu.visible = true
                    }

                    onPressed: function(mouse) {
                        hideMenu()
                        if (mouse.button === Qt.RightButton) {
                            const localPos = imageBox.mapToItem(messengerRoot, mouse.x, mouse.y)
                            let finalX = localPos.x
                            let finalY = localPos.y

                            if (finalX + menu.width > messengerRoot.width)
                                finalX = messengerRoot.width - menu.width
                            if (finalY + menu.height > messengerRoot.height)
                                finalY = messengerRoot.height - menu.height

                            var deltax = localPos.x - menu.width
                            var deltay = localPos.y - menu.height

                            if(localPos.y < menu.height)
                                deltay += menu.height
                            menu.x = deltax
                            menu.y = deltay
                            menu.message = message.text
                            menu.is_owner = owner
                            menu.type = MessegeDelegateType.Image
                            menu.messageId = messageId
                            menu.visible = true
                        }
                    }

                    onClicked: function(mouse) {
                        if(mouse.button === Qt.LeftButton && image.status === Image.Ready && !blurHashState) {
                            var file = messengerController?.storeImageToCache(message.text, !blurHashState)
                            console.log(file)
                            photoPreviewer.urlPhoto = image.source
                            photoPreviewer.idMessage = messageId
                            photoPreviewer.message =  message.text
                            photoPreviewer.visible = true
                        }

                        if(mouse.button === Qt.LeftButton && blurHashState) {
                            blurHashState = false
                        }
                    }
                }

                ColumnLayout {
                    id: clInner
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5
                    spacing: 2

                    ReplyMessageItem {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        visible: hasReplyAnswer
                        radius: _radius
                        color: messengerRoot.darkenColor(imageBox.color, _dark_k)
                        user: userInfo.text
                        replyMessage: imageDelegate.replyMessage
                        replyType: imageDelegate.replyType
                        parentMessageId: imageDelegate.parentMessageId
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: image.blur_height * imageBox.scaleFactor
                        Layout.preferredWidth: image.blur_width * imageBox.scaleFactor
                        Layout.minimumHeight: minWidth
                        Layout.minimumWidth: minWidth

                        Image {
                            anchors.fill: parent
                            source: "image://blurhash/" + encodeURIComponent(messengerController?.storeImageToCache(message.text, blurHashState))
                        }

                        Image {
                            id: image
                            anchors.centerIn: parent
                            width: sourceSize.width < (parent.width - 20) ? sourceSize.width : (parent.width - 20)
                            property real _k: sourceSize.height / sourceSize.width
                            height: width * _k

                            visible: !blurHashState

                            source: messengerController?.storeImageToCache(message.text, blurHashState)

                            property var blur_height: blurHashState ? messengerController?.heightHashBlur(message.text) : sourceSize.height
                            property var blur_width:  blurHashState ? messengerController?.widthHashBlur(message.text)  : sourceSize.width
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: 50
                            height: 50
                            running: true
                            antialiasing: true
                            visible: image.status !== Image.Ready && !blurHashState
                        }

                        ColumnLayout {
                            width: parent.width
                            height: implicitHeight
                            visible: blurHashState
                            anchors.centerIn: parent

                            Rectangle {
                                Layout.preferredHeight: image.height > 40 ? 40 : image.height-2
                                Layout.preferredWidth: Layout.preferredHeight
                                Layout.alignment: Qt.AlignHCenter
                                radius: height /2

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: adjustBrightness(Colors.messenger.file_delegate.background, _bright_koef_from)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: adjustBrightness(Colors.messenger.file_delegate.background, _bright_koef_to)
                                    }
                                }
                                IconText {
                                    anchors.centerIn: parent
                                    font.pixelSize: 22
                                    text: IcoMoon.download
                                    color: Colors.checkBox.text
                                }
                            }

                            MonserratText {
                                visible: image.source.height > 50 && image.source.width > 50
                                Layout.preferredHeight: paintedHeight
                                Layout.preferredWidth: paintedWidth
                                Layout.alignment: Qt.AlignHCenter
                                text: "Click to start load image."
                                color: Colors.detault_text_color
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: captionText.paintedHeight
                        visible: hasCaption

                        MonserratText {
                            id: captionText
                            anchors.fill: parent
                            text: caption
                            color: Colors.detault_text_color
                            wrapMode: Text.Wrap
                        }
                    }

                    MonserratText {
                        id: timeTextImage
                        Layout.fillWidth: true
                        Layout.preferredHeight: paintedHeight
                        Layout.alignment: Qt.AlignRight

                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.Wrap
                        text: Qt.formatTime(
                                  new Date(timestamp),
                                  Qt.locale().name.startsWith("en") ? (_time_format + " AP") : _time_format
                                  )
                        color: "white"
                        opacity: 0.7
                    }
                }
            }
            
            Item {
                Layout.fillWidth: visible
                Layout.preferredHeight: 1
                visible: !owner
            }
        }
    }
}
