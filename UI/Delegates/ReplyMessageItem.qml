import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"

Rectangle {
    id: box
    opacity: 0.8
    property int replyType
    property string replyMessage
    property string user
    property string parentMessageId


    signal pressedReply

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3

        Image {
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: height * scaleFactor
            property real scaleFactor: sourceSize.width / sourceSize.height
            source: visible ? box.replyMessage : ""
            visible: box.replyType === MessegeDelegateType.Image || box.replyType === MessegeDelegateType.Gif
        }

        ColumnLayout {
            Layout.leftMargin: 5
            Layout.preferredHeight: 36
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                MonserratText {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    text: userInfo.text
                    font.bold: true
                    color: Colors.button_square_send_message_style.color_icon
                    elide: Text.ElideRight
                }

                MonserratText {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    text: replyTextByType(box.replyType, box.replyMessage)
                    color: Colors.detault_text_color
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            pressedReply()
            console.log("show messege by id", parentMessageId)
            messengerController?.getIndexByMessageId(parentMessageId)
            colorFlashAnimation.restart()
        }
    }

    SequentialAnimation {
        id: colorFlashAnimation
        running: false
        loops: 1

        ColorAnimation {
            target: box
            property: "color"
            to: darkenColor(box.color, 20)
            duration: 100
            easing.type: Easing.OutQuad
        }

        ColorAnimation {
            target: box
            property: "color"
            to: box.color
            duration: 200
            easing.type: Easing.InQuad
        }
    }
}
