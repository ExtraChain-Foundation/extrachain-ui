import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCore
import QtQuick.Dialogs
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Qt.labs.qmlmodels
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"

Item {
    id: gifDelegate
    height: cl.implicitHeight
    property int maxWidth: 500
    property int minWidth: 100
    property bool isShowDateSeparator: false
    property bool hasReplyAnswer: false
    property int replyType: MessegeDelegateType.Text
    property string replyMessage
    property string parentMessageId

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
        spacing: 5
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: gifDelegate.isShowDateSeparator ? 24 : 0
            Layout.preferredWidth: daySeparateTextForGif.paintedWidth + 16
            color: Colors.messenger.day_separator
            radius: height/2
            
            MonserratText {
                id: daySeparateTextForGif
                visible: gifDelegate.isShowDateSeparator ? true : false
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
                Layout.minimumWidth: gifDelegate.minWidth
                visible: owner
            }
            
            Rectangle {
                id: gifBox
                readonly property int _min_w_and_h: 75
                property real scaleFactor: Math.min(1, maxWidth / gifImage.sourceSize.width)

                Layout.preferredWidth: gifImage.status === Image.Ready ? (gifImage.sourceSize.width * scaleFactor) : _min_w_and_h
                Layout.maximumWidth: Layout.preferredWidth
                Layout.minimumWidth: Layout.preferredWidth
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
                    color_in: gifBox.color
                    _target: gifBox
                }

                MouseArea {
                    id: mouseMenuGif
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    propagateComposedEvents: true
                    z: -1

                    onPressAndHold: {
                        if(!root.isMobile)
                            return;
                        hideMenu()
                        var point = gifImage.mapToItem(messengerRoot, 0, 0)
                        console.log(point)

                        menu.x = point.x + gifBox.width - menu.width
                        if(point.y >= menu.height)
                            menu.y = point.y - menu.height - 2
                        else
                            menu.y = point.y + gifBox.height
                        menu.type = MessegeDelegateType.Gif
                        menu.message = messageText.text
                        console.log("messageId", messageId)
                        menu.messageId = messageId
                        chatItem.grabToImage(function(result) {
                            // console.info("result grab", result)
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
                            const localPos = gifBox.mapToItem(messengerRoot, mouse.x, mouse.y)
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
                            menu.type = MessegeDelegateType.Gif
                            menu.message = message.text
                            console.log("messageId", messageId)
                            menu.messageId = messageId
                            menu.visible = true
                        }
                    }

                    onClicked: function(mouse) {
                        hideMenu()
                        if (mouse.button === Qt.RightButton) {
                            const localPos = gifBox.mapToItem(messengerRoot, mouse.x, mouse.y)
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
                            menu.type = MessegeDelegateType.Gif
                            menu.message = message.text
                            console.log("messageId", messageId)
                            menu.messageId = messageId
                            menu.visible = true
                        }

                        if (mouse.button === Qt.LeftButton) {
                            photoPreviewer.gifMode = true
                            photoPreviewer.urlPhoto = gifImage.source
                            photoPreviewer.idMessage = messageId
                            photoPreviewer.visible = true
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
                        color: messengerRoot.darkenColor(gifBox.color, _dark_k)
                        user: userInfo.text
                        replyMessage: gifDelegate.replyMessage
                        replyType: gifDelegate.replyType
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 50
                        Layout.minimumHeight: 50
                        readonly property int _min_w_and_h: 75
                        property real scaleFactor: Math.min(1, maxWidth / gifImage.sourceSize.width)
                        Layout.preferredWidth: gifImage.status === Image.Ready ? (gifImage.sourceSize.width * scaleFactor) : _min_w_and_h
                        Layout.preferredHeight: gifImage.status === Image.Ready ? (gifImage.sourceSize.height * scaleFactor) : _min_w_and_h

                        AnimatedImage {
                            id: gifImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            anchors.margins: 5
                            source: message.text
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: 50
                            height: 50
                            running: true
                            antialiasing: true
                            visible: gifImage.status !== Image.Ready
                        }
                    }

                    MonserratText {
                        id: timeTextGif
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
