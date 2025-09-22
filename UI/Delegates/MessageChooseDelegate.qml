import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"

SwipeDelegate {
    id: swipeDelegate

    signal replyRequested(var message)

    required property string message_type
    required property int index
    required property string message_text
    required property string sender
    required property string timestamp
    property bool owner: true

    background: Rectangle {
        color: "transparent"
    }

    contentItem: ColumnLayout {
        spacing: 5
        width: parent.width

        Item {
            width: 1; height: 5
        }

        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignLeft

            Rectangle {
                id: bubble
                color: sender === "me" ? Colors.messenger.choose_delegate.me : Colors.messenger.choose_delegate.not_me
                radius: 10
                Layout.maximumWidth: swipeDelegate.maxWidth
                Layout.minimumWidth: swipeDelegate.minWidth
                Layout.preferredWidth: implicitWidth
                Layout.alignment: sender === "me" ? Qt.AlignRight : Qt.AlignLeft

                Column {
                    id: messageColumn
                    padding: 10
                    spacing: 5
                    width: parent.width

                    Loader {
                        id: contentLoader
                        width: parent.width
                        sourceComponent: {
                            console.log("messageType_", message_type, message_text)
                            if (message_type === "text")
                                return textComponent
                            else if (message_type === "image")
                                return imageComponent
                            else if (message_type === "file")
                                return fileComponent
                            else
                                return unknownComponent
                        }
                    }

                    Component {
                        id: textComponent
                        Rectangle {
                            id: delegate
                            width: swipeDelegate.width
                            height: messageText.implicitHeight + 50 + dataItem.height
                            property int maxWidth: swipeDelegate.width * 0.7
                            property int minWidth: ((swipeDelegate.width * 0.3) - 20)

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                Rectangle {
                                    id: dataItem
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredHeight: chatList.isShowDateSeparator(index, timestamp) ? 24 : 0
                                    Layout.preferredWidth: daySeparateText.paintedWidth + 16
                                    color: Colors.messenger.day_separator
                                    radius: 4

                                    MonserratText {
                                        id: daySeparateText
                                        visible: chatList.isShowDateSeparator(index, timestamp) ? true : false
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
                                        Layout.minimumWidth: delegate.minWidth
                                        visible: owner
                                    }

                                    Rectangle {
                                        id: messageBox
                                        Layout.maximumWidth: Math.min(messageText.implicitWidth + timeText.implicitWidth + 30, delegate.maxWidth + 10)
                                        Layout.preferredWidth: Math.min(messageText.implicitWidth + timeText.implicitWidth + 30, delegate.maxWidth + 10)
                                        Layout.minimumWidth: Math.max(messageText.implicitWidth + 20, timeText.implicitWidth + 15)
                                        Layout.preferredHeight: messageText.implicitHeight + 25
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

                                        TextEdit {
                                            id: messageText
                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: 10
                                            anchors.bottomMargin: 20

                                            text: message_text
                                            readOnly: true
                                            wrapMode: TextEdit.Wrap
                                            color: "white"
                                            selectByMouse: true
                                            cursorVisible: true
                                            font.family: Montserrat.monserrat
                                        }

                                        MonserratText {
                                            id: timeText
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 5
                                            font.pixelSize: 10
                                            text: Qt.formatDateTime(new Date(timestamp), "HH:mm:ss");
                                            color: "white"
                                            opacity: 0.7
                                        }

                                        MouseArea {
                                            id: mouseMenu
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                                            onPressed: function(mouse) {
                                                if (mouse.button === Qt.RightButton) {
                                                    if (mouse.button === Qt.RightButton) {

                                                        const localPos = mouseMenu.mapToItem(messengerRoot, mouse.x, mouse.y)

                                                        // Уточнена перевірка, щоб меню не виходило за межі вікна
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
                                                        menu.visible = true
                                                        menuAddFile.visible = false
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: visible
                                        Layout.preferredHeight: 1
                                        Layout.minimumWidth: visible ? delegate.minWidth : 0
                                        visible: !owner
                                    }
                                }
                            }
                        }
                    }

                    Component {
                        id: imageComponent
                        Image {
                            fillMode: Image.PreserveAspectFit
                            width: parent.width
                            height: 150
                        }
                    }

                    Component {
                        id: fileComponent
                        Row {
                            spacing: 5
                            Image {
                                width: 24
                                height: 24
                            }
                            Text {
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Component {
                        id: unknownComponent
                        Text {
                            text: "Unsupported content"
                        }
                    }
                }
            }
        }
    }

    onReleased: {
        if (swipe.position > swipe.maximumPosition * 0.7) {
            swipeDelegate.replyRequested(messageData)
            swipeDelegate.swipe.complete()
        }
    }
}
