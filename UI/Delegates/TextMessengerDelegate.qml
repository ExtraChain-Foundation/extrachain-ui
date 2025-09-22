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
    id: messageDelegate
    height: cl.implicitHeight + 20
    property int maxWidth: chatList.width * 0.7
    property int minWidth: ((chatList.width * 0.3) - 20)
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
        spacing: 0
        
        Rectangle {
            id: dataItem
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: messageDelegate.isShowDateSeparator ? 24 : 0
            Layout.preferredWidth: daySeparateText.paintedWidth + 16
            color: Colors.messenger.day_separator
            radius: height/2
            
            MonserratText {
                id: daySeparateText
                visible: messageDelegate.isShowDateSeparator
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
                Layout.minimumWidth: messageDelegate.minWidth
                visible: owner
            }
            
            Rectangle {
                id: messageBox
                Layout.maximumWidth: Math.min(messageText.implicitWidth + timeText.implicitWidth + 30, messageDelegate.maxWidth + 10)
                Layout.preferredWidth: Math.min(messageText.implicitWidth + timeText.implicitWidth + 30, messageDelegate.maxWidth + 10)
                Layout.minimumWidth: Math.max(messageText.implicitWidth + 20, timeText.implicitWidth + 15)
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
                    color_in: messageBox.color
                    _target: messageBox
                }

                MouseArea {
                    id: mouseMenu
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton | Qt.LeftButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    enabled: !messageText.containsMouse
                    visible: !messageText.containsMouse
                    z: -1

                    onPressed: function(mouse) {
                        hideMenu()
                        if (mouse.button === Qt.RightButton) {
                            const localPos = messageBox.mapToItem(messengerRoot, mouse.x, mouse.y)
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
                            menu.type = MessegeDelegateType.Text
                            menu.message = messageText.text
                            menu.messageId = messageId
                            menu.owner = owner
                            console.log("messageId", messageId, menu.answer_user, owner)
                            menu.visible = true
                        }
                    }

                    onPressAndHold: {
                        if (!root.isMobile || messageText.containsMouse)
                            return;
                        hideMenu()
                        var point = messageBox.mapToItem(messengerRoot, 0, 0)

                        menu.x = point.x + messageBox.width - menu.width
                        if(point.y >= menu.height)
                            menu.y = point.y - menu.height - 2
                        else
                            menu.y = point.y + messageBox.height
                        menu.type = MessegeDelegateType.Text
                        menu.message = messageText.text
                        console.log("messageId", messageId)
                        menu.messageId = messageId
                        menu.owner = owner
                        chatItem.grabToImage(function(result) {
                            if (result) {
                                screenshotImage.source =  result.url
                                blurEffect.source = screenshotImage
                                screenshotImage.visible = true
                                var p = messageDelegate.mapToItem(chatItem, 0, 0)
                                dublicateMessageRect.width = messageBox.width
                                dublicateMessageRect.height = messageBox.height
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
                        color: messengerRoot.darkenColor(messageBox.color, _dark_k)
                        user: userInfo.text
                        replyMessage: messageDelegate.replyMessage
                        replyType: messageDelegate.replyType
                        parentMessageId: messageDelegate.parentMessageId
                    }

                    TextEdit {
                        id: messageText
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        text: {
                            switch(type) {
                            case 1: return "chat created"
                            case 2: return "invite " + message.text
                            case 3: return message.text + " joined"
                            default: return message.text
                            }
                        }

                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        textFormat: chatsModel.type === 2 ? Text.MarkdownText : Text.PlainText
                        color: "white"
                        selectByMouse: true
                        font.family: Montserrat.monserrat
                        cursorVisible: true
                        selectionColor: Colors.messenger.video_delegate.icon
                        selectedTextColor: "white"
                        focus: false
                    }

                    MonserratText {
                        id: timeText
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
                Layout.minimumWidth: visible ? messageDelegate.minWidth : 0
                visible: !owner
            }
        }
    }
}
