import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"

Item {
    id: fileDelegate
    height: cl.implicitHeight
    property int maxWidth
    property int minWidth
    property bool isShowDateSeparator: false
    property bool hasReplyAnswer: false
    property int replyType: MessegeDelegateType.Text
    property string replyMessage
    property string parentMessageId
    property bool hasCaption: false
    property string caption

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
        spacing: 0
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight:  isShowDateSeparator ? 24 : 0
            Layout.preferredWidth: daySeparateTextForFile.paintedWidth + 16
            color: Colors.messenger.day_separator
            radius: height/2
            visible: isShowDateSeparator
            
            MonserratText {
                id: daySeparateTextForFile
                visible: isShowDateSeparator
                anchors.centerIn: parent
                text: new Date(timestamp).toLocaleDateString()
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: Colors.messenger.day_separator_text
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: clInner.implicitHeight + 20

            spacing: 0
            
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.minimumWidth: fileDelegate.minWidth
                visible: owner
            }

            Rectangle {
                id: fileBox
                
                Layout.preferredWidth: 200
                Layout.maximumWidth: maxWidth
                Layout.minimumWidth: minWidth
                Layout.preferredHeight: clInner.implicitHeight + 10

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
                    color_in: fileBox.color
                    _target: fileBox
                }

                MouseArea {
                    id: mouseMenuFile
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    z: -1

                    onPressAndHold: {
                        if(!root.isMobile)
                            return;
                        hideMenu()
                        var point = fileBox.mapToItem(messengerRoot, 0, 0)
                        console.log(point)

                        menu._file_delegate = true
                        menu.x = point.x + fileBox.width - menu.width
                        if(point.y >= menu.height)
                            menu.y = point.y - menu.height - 2
                        else
                            menu.y = point.y + fileBox.height
                        menu.type = MessegeDelegateType.File
                        menu.message = message.text
                        console.log("messageId", messageId)
                        menu.messageId = messageId
                        chatItem.grabToImage(function(result) {
                            // console.info("result grab", result)
                            if (result) {
                                screenshotImage.source =  result.url
                                blurEffect.source = screenshotImage
                                screenshotImage.visible = true
                                var p = fileDelegate.mapToItem(chatItem, 0, 0)
                                dublicateMessageRect.width = fileBox.width
                                dublicateMessageRect.height = fileBox.height
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

                    onClicked: function(mouse) {
                        hideMenu()
                        if (mouse.button === Qt.RightButton) {
                            const localPos = fileBox.mapToItem(messengerRoot, mouse.x, mouse.y)
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
                            menu.type = MessegeDelegateType.File
                            menu.message = message.text
                            console.log("messageId", messageId)
                            menu.messageId = messageId
                            menu._file_delegate = true
                            menu.visible = true
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
                        color: messengerRoot.darkenColor(fileBox.color, _dark_k)
                        user: userInfo.text
                        replyMessage: fileDelegate.replyMessage
                        replyType: fileDelegate.replyType
                    }

                    RowLayout {
                        id: rl
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        IconText {
                            id: iconFile
                            Layout.fillHeight: true
                            Layout.preferredWidth: Layout.preferredHeight
                            Layout.alignment: Qt.AlignVCenter
                            text: IcoMoon.file
                            font.pixelSize: 24
                            color: Colors.messenger.file_delegate.icon
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            MonserratText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                color: Colors.detault_text_color
                                text: messengerController?.getFileNameFromMessage(message.text)
                                elide: Text.ElideMiddle
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
                        id: timeTextFile
                        Layout.fillWidth: true
                        Layout.preferredHeight: paintedHeight
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignRight
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
                Layout.minimumWidth: visible ? fileDelegate.minWidth : 0
                visible: !owner
            }
        }
    }
}
