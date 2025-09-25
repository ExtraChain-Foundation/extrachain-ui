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


Popup {
    id: popupAddFiles
    property var file
    property var listFiles
    property bool isImage: false
    property bool isFile: false
    property bool isVideo: false
    property string nameFile
    
    anchors.centerIn: parent
    width: 400
    height: clPopup.implicitHeight + 10
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    Overlay.modal: Rectangle {
        color: Colors.background
        opacity: 0.2
    }
    
    onVisibleChanged: {
        if(!visible) {
            isImage = false
            isFile = false
            isVideo = false
            textAreaCaption.text = ""
        }
    }
    
    background: Rectangle {
        radius: _radius
        color: Colors.menuPopup.background
    }
    
    contentItem: Item {
        ColumnLayout {
            id: clPopup
            anchors.fill: parent
            spacing: 5
            
            SquareButton {
                Layout.preferredHeight: 30
                Layout.preferredWidth: 30
                Layout.alignment: Qt.AlignRight
                icon: IcoMoon.close
                koef_icon_size: 0.8
                onClicked: {
                    popupAddFiles.close()
                }
            }
            
            Item {
                id: imgPopupBox
                
                property real maxHeight: 400
                property real rawScale: Math.min(clPopup.width / imgPopup.sourceSize.width,
                                                 clPopup.height / imgPopup.sourceSize.height)
                property real heightScaleLimit: maxHeight / imgPopup.sourceSize.height
                property real scaleFactor: Math.min(1, rawScale, heightScaleLimit)
                
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: imgPopup.sourceSize.width * scaleFactor
                Layout.preferredHeight: imgPopup.sourceSize.height * scaleFactor
                visible: popupAddFiles.isImage
                
                Image {
                    id: imgPopup
                    anchors.centerIn: parent
                    source: popupAddFiles.file
                    visible: popupAddFiles.isImage
                    antialiasing: true
                    width: imgPopup.sourceSize.width * parent.scaleFactor
                    height: imgPopup.sourceSize.height * parent.scaleFactor
                }
                
                layer.enabled: popupAddFiles.isImage
                layer.effect: DropShadow {
                    horizontalOffset: 1
                    verticalOffset: 0
                    radius: 10
                    samples: 32
                    color: Colors.default_shadow
                }
            }
            
            RowLayout {
                Layout.preferredHeight: 40
                Layout.fillWidth: true
                visible: popupAddFiles.isFile || popupAddFiles.isVideo
                
                Item {
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 50
                    
                    IconText {
                        anchors.centerIn: parent
                        font.pixelSize: 28
                        text: popupAddFiles.isFile ? IcoMoon.file : IcoMoon.video
                        color: Colors.detault_text_color
                    }
                }
                
                MonserratText {
                    Layout.preferredHeight: 50
                    Layout.fillWidth: true
                    text: popupAddFiles.nameFile
                    verticalAlignment: Text.AlignVCenter
                    color: Colors.detault_text_color
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }
            
            Item {
                Layout.preferredHeight: 10
                Layout.preferredWidth: 2
            }
            
            MonserratText {
                Layout.preferredHeight: paintedHeight
                Layout.fillWidth: true
                text: "Caption"
                color: Colors.detault_text_color
                font.pixelSize: 16
            }
            
            ScrollView {
                id: addfileScrollView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(100, Math.max(30, textAreaCaption.implicitHeight + (textAreaCaption.lineCount > 1 ? 2 : 0)))
                anchors.margins: 1
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.interactive: false
                
                TextArea {
                    id: textAreaCaption
                    wrapMode: TextEdit.Wrap
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: Colors.detault_text_color
                    font.family: Montserrat.monserrat
                    font.pixelSize: 14
                    selectByMouse: true
                    topPadding: 14
                    focus: true
                    background: Rectangle {
                        color: Colors.text_field_style.background
                        radius: _radius
                    }
                }
            }
            
            ExButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.minimumHeight: 50
                text: "Send message"
                onClicked: {
                    messengerController?.addFiles(popupAddFiles.listFiles, fileDialog.all_file_mode, chatsModel.current_chat_id, menu.messageId, textAreaCaption.text)
                    popupAddFiles.close()
                }
            }
            
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
            }
        }
    }
}
