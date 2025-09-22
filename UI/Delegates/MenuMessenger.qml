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


Rectangle {
    id: menu
    property int parent_index: -1
    property bool is_owner: true
    property string message
    property string messageId
    property string reply_message
    property bool owner
    readonly property int _margin: 5
    readonly property int _h_icon: 30
    readonly property int _size_icon: 18
    property bool _file_delegate: false
    property int type
    
    width: max_width_text() + (2 * _margin) + _h_icon
    height: cl.implicitHeight
    visible: false
    radius: _radius
    color: Colors.messenger.menu.background
    
    onVisibleChanged: {
        if(!visible) {
            _file_delegate = false
            is_owner = true
            te.forceActiveFocus()
        } else {
            menu.width =  max_width_text() + (2 * _margin) + _h_icon
            te.focus = false
        }
    }
    
    ColumnLayout {
        id: cl
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            //first element menu
            Layout.fillHeight: true
            Layout.preferredHeight: 40
            Layout.fillWidth: true
            radius: _radius
            color: Colors.messenger.menu.background
            opacity: copyMouseArea.containsMouse ? 0.7 : 1.0
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
                opacity: copyMouseArea.pressed ? 0.7 : 1.0
                visible: cl.implicitHeight > 40
            }
            
            MouseArea {
                id: copyMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    var e = (menu._file_delegate === true)
                    menu.visible = false
                    if(e) {
                        exportFileDialog.open()
                    } else {
                        etUtils.copyToClipboard(menu.message.replace("\\", "/"))
                        notificationToolTip.showMessage("Copied.", Tooltip.CopiedAddress)
                    }
                    hideMenu()
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
                        text: menu._file_delegate ? qsTr("Export file") : qsTr("Copy")
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
            visible: menu.is_owner
        }
        
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredHeight: 40
            Layout.fillWidth: true
            radius: _radius
            color: Colors.messenger.menu.background
            opacity: editMouseArea.containsMouse ? 0.7 : 1.0
            visible: menu.type == MessegeDelegateType.Text
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
                opacity: editMouseArea.pressed ? 0.7 : 1.0
            }
            
            MouseArea {
                id: editMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    console.log("edit", menu.message, menu.messageId)
                    cached_text_message = te.text
                    menu.reply_message = menu.message
                    replyBox.messageId = menu.messageId
                    replyBox.current_type = menu.type
                    replyBox.message = menu.message
                    te.text = menu.message
                    te.cursorPosition = te.text.length

                    edit_state = true
                    hideMenu()
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
                            text: IcoMoon.edit
                            color: Colors.checkBox.text
                            opacity: editMouseArea.pressed ? 0.7 : 1.0
                        }
                    }
                    
                    MonserratText {
                        id: edit_reply_text
                        Layout.preferredHeight: parent.height
                        Layout.fillWidth: true
                        text: qsTr("Edit")
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
            visible: menu.type == MessegeDelegateType.Text
        }
        
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredHeight: 40
            Layout.fillWidth: true
            radius: _radius
            color: Colors.messenger.menu.background
            opacity: replyMouseArea.containsMouse ? 0.7 : 1.0
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.radius
                color: parent.color
                opacity: replyMouseArea.pressed ? 0.7 : 1.0
            }
            
            MouseArea {
                id: replyMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    console.log("reply", menu.message, menu.messageId)
                    menu.reply_message = menu.message
                    replyBox.messageId = menu.messageId
                    replyBox.current_type = menu.type
                    replyBox.message = menu.message
                    reply_state = true
                    hideMenu()
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
                            text: IcoMoon.reply
                            color: Colors.checkBox.text
                            opacity: copyMouseArea.pressed ? 0.7 : 1.0
                        }
                    }
                    
                    MonserratText {
                        id: menu_reply_text
                        Layout.preferredHeight: parent.height
                        Layout.fillWidth: true
                        text: qsTr("Reply")
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
            Layout.preferredHeight: 40
            radius: _radius
            color: Colors.messenger.menu.background
            opacity: deleteArea.containsMouse ? 0.7 : 1.0
            visible: menu.is_owner
            
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
                    hideMenu()
                    messengerController?.removeMessage(menu.messageId)
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
            var folderPath = Qt.platform.os === "windows"
                    ? folderUrl.toString().replace("file:///", "")
                    : folderUrl.toString().replace("file://", "");
            console.log("Selected folder:", folderPath)
            let path = folderPath.substring(0, folderPath.lastIndexOf("/"))
            console.log("Parent folder:", path)
            messengerController?.exportFile(menu.message, path)
        }
    }
    
    function max_width_text() {
        var res = menu_copy_text.paintedWidth;
        if(menu_delete_text.paintedWidth > res)
            res = menu_delete_text.paintedWidth
        return res + (2 * _margin) + _h_icon
    }
}
