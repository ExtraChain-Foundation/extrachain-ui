import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Pages"
import "../Fonts"
import "../"

Popup {
    id: editWalletPopup
    y: parent.height - height
    modal: false
    focus: true
    height: cl.implicitHeight + 60
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    property string name_wallet
    property string index
    property string id_wallet
    property bool _v: isMobile
    
    
    Overlay.modal: BlackRectangle { opacity: 0.9 }
    
    background: Rectangle {
        color: Colors.wallet.background
        radius: 8
        Rectangle{
            anchors.bottom: parent.bottom
            width: parent.width
            height: 8
            color: parent.color
        }
    }
    
    contentItem: Item {
        ColumnLayout{
            id: cl
            anchors.centerIn: parent
            height: implicitHeight
            width: parent.width - 32
            spacing: 34
            
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * visible
                opacity: parent.pressed ? 0.7 : 1.0
                
                RowLayout {
                    anchors.fill: parent
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.copy
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }
                    
                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Copy address"
                        font.pixelSize: 16
                    }
                }
                
                onClicked: {
                    walletUIController.copyWalletAddress(editWalletPopup.id_wallet)
                    notificationToolTip.showMessage("ADDERESS COPIED TO CLIPBOARD", Tooltip.CopiedAddress, "")
                    editWalletPopup.close()
                }
            }
            
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * visible
                onClicked: {
                    console.log("begin rename wallet", editWalletPopup.id_wallet, editWalletPopup.name_wallet, editWalletPopup.index)
                    walletPage.renameWallet(editWalletPopup.id_wallet, editWalletPopup.name_wallet, editWalletPopup.index)
                    editWalletPopup.close()
                }
                
                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.edit
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }
                    
                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Rename wallet"
                        font.pixelSize: 16
                    }
                }
            }
            
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * visible
                visible: false
                onClicked: {
                    if (!isNewProfile) {
                        showExportPage()
                    }

                    editWalletPopup.close()
                }
                
                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.key
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }
                    
                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Export private key"
                        font.pixelSize: 16
                    }
                }
            }
            
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * visible
                visible: false//!isNewProfile
                onClicked: {
                    if (!isNewProfile) {
                        showExportPage()
                    }

                    editWalletPopup.close()
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.down
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }
                    
                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Export recovery phrase"
                        font.pixelSize: 16
                    }
                }
            }
            
            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * visible
                visible: false
                
                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.trash
                        color: Colors.red
                        font.pixelSize: 16
                    }
                    
                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.red
                        text: "Delete"
                        font.pixelSize: 16
                    }
                }
            }
        }
    }
}
