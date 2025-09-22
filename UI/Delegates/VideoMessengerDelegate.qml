import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"

Item {
    id: videoDelegate
    height: cl.implicitHeight + 20
    property int maxWidth: 500
    property int minWidth: hasCaption && caption.length > 0 ? (captionText.paintedWidth + 20) : 50
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
            Layout.preferredHeight: videoDelegate.isShowDateSeparator ? 24 : 0
            Layout.preferredWidth: daySeparateTextForVideo.paintedWidth + 16
            color: Colors.messenger.day_separator
            radius: height/2

            MonserratText {
                id: daySeparateTextForVideo
                visible: videoDelegate.isShowDateSeparator ? true : false
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
                Layout.minimumWidth: videoDelegate.minWidth
                visible: owner
            }

            Rectangle {
                id: videoBox

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
                    color_in: videoBox.color
                    _target: videoBox
                }

                MouseArea {
                    id: mouseMenuVideo
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    propagateComposedEvents: true
                    z: -1

                    onPressAndHold: {
                        if(!root.isMobile)
                            return;
                        hideMenu()
                        var point = videoBox.mapToItem(messengerRoot, 0, 0)
                        console.log(point)

                        menu._file_delegate = true
                        menu.x = point.x + videoBox.width - menu.width
                        if(point.y >= menu.height)
                            menu.y = point.y - menu.height - 2
                        else
                            menu.y = point.y + videoBox.height
                        menu.type = MessegeDelegateType.Video
                        menu.message = messageText.text
                        menu.messageId = messageId
                        chatItem.grabToImage(function(result) {
                            if (result) {
                                screenshotImage.source =  result.url
                                blurEffect.source = screenshotImage
                                screenshotImage.visible = true
                                var p = messageDelegate.mapToItem(chatItem, 0, 0)
                                dublicateMessageRect.width = videoBox.width
                                dublicateMessageRect.height = videoBox.height
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
                            }
                        })

                        menu.visible = true
                    }

                    onPressed: function(mouse) {
                        hideMenu()
                        if (mouse.button === Qt.RightButton) {
                            const localPos = videoBox.mapToItem(messengerRoot, mouse.x, mouse.y)
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
                            menu._file_delegate = true
                            menu.x = deltax
                            menu.y = deltay
                            menu.type = MessegeDelegateType.Video
                            menu.message = message.text
                            menu.messageId = messageId
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
                        color: messengerRoot.darkenColor(videoBox.color, _dark_k)
                        user: userInfo.text
                        replyMessage: videoDelegate.replyMessage
                        replyType: videoDelegate.replyType
                    }

                    RowLayout {
                        id: rl
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        IconText {
                            Layout.fillHeight: true
                            Layout.preferredWidth: Layout.preferredHeight
                            Layout.alignment: Qt.AlignVCenter
                            text: IcoMoon.video
                            font.pixelSize: 20
                            color: Colors.messenger.video_delegate.icon
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
                        id: timeTextVideo
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
                Layout.minimumWidth: visible ? gifDelegate.minWidth : 0
                visible: !owner
            }
        }
    }
}
