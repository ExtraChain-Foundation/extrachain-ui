import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"

Rectangle {
    id: replyBox
    height: visible ? 50 : 0
    color: Colors.text_field_style.background
    property string messageId
    property int current_type
    property string message
    
    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        
        IconText {
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            text: IcoMoon.reply
            color: Colors.button_square_send_message_style.color_icon
        }
        
        Image {
            id: replyImage
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: height * scaleFactor
            property real scaleFactor: sourceSize.width / sourceSize.height
            visible: replyBox.current_type === MessegeDelegateType.Image  && status === Image.Ready
            source: messengerController?.storeImageToCache(replyBox.message)
        }
        
        AnimatedImage {
            id: replyAnimImage
            Layout.preferredHeight: 36
            Layout.preferredWidth: 36
            visible: replyBox.current_type === MessegeDelegateType.Gif && status === Image.Ready
            source: replyBox.message
        }

        IconText {
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            text: (() => { switch (replyBox.current_type) {
                            case MessegeDelegateType.File: return IcoMoon.file
                            case MessegeDelegateType.Video: return IcoMoon.video

                        }})()
            color: Colors.button_square_send_message_style.color_icon
            visible: replyBox.current_type === MessegeDelegateType.File || replyBox.current_type === MessegeDelegateType.Video
            font.pixelSize: replyBox.current_type === MessegeDelegateType.File ? 24 : 20
        }
        
        BusyIndicator {
            Layout.maximumWidth: 40
            Layout.maximumHeight: Layout.maximumWidth
            Layout.preferredWidth: Layout.maximumWidth
            Layout.preferredHeight: Layout.maximumWidth
            running: true
            antialiasing: true
            visible: (() => {
                          switch (replyBox.current_type) {
                              case MessegeDelegateType.Gif:
                              return replyAnimImage.status !== Image.Ready
                              case MessegeDelegateType.Image:
                              return replyImage.status !== Image.Ready
                              default:
                              return false
                          }
                      })()
        }
        
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            
            MonserratText {
                Layout.fillHeight: true
                Layout.fillWidth: true
                text: messengerRoot.reply_state ? "Reply to " + (menu.owner ? uiController.loadUserName(raccoonController?.mainActor) : userInfo.text) : "Edit message"
                font.bold: true
                color: Colors.button_square_send_message_style.color_icon
            }
            
            MonserratText {
                Layout.fillHeight: true
                Layout.fillWidth: true
                text: replyTextByType(replyBox.current_type, message)
                color: Colors.detault_text_color
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
        
        SquareButton {
            Layout.fillHeight: true
            Layout.preferredWidth: 40
            width: 50
            height: width
            style: Colors.wallet_withdraw_page.button_back_style
            size: parent.width
            icon: IcoMoon.close
            onClicked: {
                if(reply_state)
                    reply_state = false
                if(edit_state)
                    edit_state = false
            }
        }
    }
}
