import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore as QtCore
import ExtraChain 1.0

import "../Controls"
import "../Fonts"

ColumnLayout {
    id: clDialog
    anchors.fill: parent

    property var phrases
    property alias _hex: hexExportBlock.hex
    property alias _phrasesModel: repeaterMnemonicPhase.model

    function reset() {
        phase1.checked = false
        phase2.checked = false
        protectCheckBox.checked = false
        protectCheckBox2.checked = false
    }

    onVisibleChanged: {
        phase1.checked = false
        phase2.checked = false
        protectCheckBox.checked = false
    }
    
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 64 : 0
        Layout.maximumHeight: 64
        
        SquareButton {
            Layout.preferredHeight: 32
            Layout.preferredWidth: 32
            Layout.alignment: Qt.AlignVCenter
            icon: IcoMoon.down
            rotation: 90
            menu_button: true
            onClicked: {
                if(isMobile)
                    exportMobileDialog.visible = false
                else
                    exportDialog.close()
            }
        }
        
        DmsansText {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            text: "Export profile"
            font.pixelSize: 24
            color: Colors.def_color_text
            verticalAlignment: Text.AlignVCenter
        }
    }
    
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 48 : 0
    }

    ExTextField {
        id: exportProfileTf
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 48 : 0
        text: "ExtraChain"
        placeholderText: "File name"
        font.pixelSize: 16
        visible: !exportDialog.is_new_version
    }
    
    Item {
        Layout.preferredHeight: 20
        Layout.fillWidth: true
        visible: !exportDialog.is_new_version
    }
    
    Item  {
        Layout.fillWidth: true
        Layout.preferredHeight: 10
    }
    
    DmsansText {
        id: hexExportBlock
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? paintedHeight : 0
        visible: exportDialog.is_new_version && exportDialog.type === 2
        property string hex
        color: Colors.def_color_text
        font.pixelSize: 14
        text: "<b>Hex Phrase</b> (encrypted by login and password):<br><br>" + hex
        wrapMode: Text.Wrap
    }
    
    Flow {
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        spacing: 4
        visible: exportDialog.is_new_version && exportDialog.type === 1
        
        Repeater {
            id: repeaterMnemonicPhase
            
            Rectangle {
                width: rlFlowDelegate.implicitWidth
                height: 24
                color: Colors.export_page.background
                border.color: Colors.grape_gray_color
                radius: 4
                
                RowLayout {
                    id: rlFlowDelegate
                    anchors.fill: parent
                    spacing: 7
                    
                    DmsansText {
                        Layout.leftMargin: 2
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: paintedWidth
                        leftPadding: 4
                        text: index + 1
                        font.pixelSize: 12
                        color: Colors.green
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    DmsansText {
                        Layout.rightMargin: 2
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: paintedWidth
                        rightPadding: 4
                        text: modelData
                        font.pixelSize: 12
                        color: Colors.def_color_text
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    
    Item {
        Layout.preferredHeight: 20
        Layout.fillWidth: true
        visible: exportDialog.is_new_version
    }
    
    ExCheckBox {
        id: protectCheckBox
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 50 : 0
        text: "I understand that my wallet data will be securely encrypted with my login and password."
        checked: false
        visible: exportDialog.type === 0 || exportDialog.type === 2
    }

    ExCheckBox {
        id: protectCheckBox2
        Layout.fillWidth: true
        Layout.preferredHeight: visible ? 50 : 0
        text: "I understand that if I lose my recovery file, I will permanently lose access to my wallet and funds."
        checked: false
        visible: exportDialog.type === 0
    }
    
    ExCheckBox {
        id: phase1
        Layout.preferredHeight: 30
        Layout.fillWidth: true
        text: "I understand that if I lose my recovery " + (exportDialog.type === 1 ? "phrase" : "hex") + ", I will permanently lose access to my wallet and funds."
        checked: false
        visible: exportDialog.is_new_version
    }
    
    Item {
        Layout.preferredHeight: 20
        Layout.fillWidth: true
        visible: exportDialog.is_new_version
    }
    
    ExCheckBox {
        id: phase2
        Layout.preferredHeight: 30
        Layout.fillWidth: true
        text: "I understand that I must never share my recovery " + (exportDialog.type === 1 ? "phrase" : "hex") + " with anyone"
        checked: false
        visible: exportDialog.is_new_version
    }
    
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
    }
    
    BlueButton {
        id: registrationButton
        Layout.preferredHeight: 40
        Layout.preferredWidth: 180
        Layout.alignment: Qt.AlignHCenter
        text: "Copy Recovery " + (exportDialog.type === 1 ? "Phrase" : "Hex")
        visible: exportDialog.is_new_version
        filled: true
        enabled: (phase2.checked && phase1.checked) && (exportDialog.type === 2 ? protectCheckBox.checked : true)
        onClicked: {
            if(exportDialog.type === 1) {
                console.log("Copy recovery phrase")
                var fullPhrase = ""
                var modelArray = repeaterMnemonicPhase.model
                for (let i = 0; i < modelArray.length; ++i) {
                    fullPhrase += modelArray[i] + ' '
                }
                console.log("Full phrase:", fullPhrase.trim())
                walletUIController.copyWalletAddress(fullPhrase.trim())
                notificationToolTip.showMessage("Recovery Phrase copied", Tooltip.CopiedAddress)

            } else if(exportDialog.type === 2) {
                walletUIController.copyWalletAddress(hexExportBlock.hex)
                notificationToolTip.showMessage("Hex copied", Tooltip.CopiedAddress)
            }
        }
    }
    
    BlueButton {
        id: exportProfileButton
        Layout.preferredWidth: 140
        Layout.preferredHeight: 48
        Layout.alignment: Qt.AlignHCenter
        text: "Export profile"
        filled: true
        visible: exportDialog.type === 0
        enabled: protectCheckBox.checked && (exportDialog.is_new_version ? (phase1.checked && phase2.checked) : (exportProfileTf.text.length >= 5)) && protectCheckBox2.checked
        
        function nameExportedFileName(text) {
            const usymbol = '_'
            const now = new Date()
            const formattedDate = now.getFullYear() + usymbol +
                                String(now.getMonth() + 1).padStart(2, '0') + usymbol +
                                String(now.getDate()).padStart(2, '0') + usymbol +
                                String(now.getHours()).padStart(2, '0') + usymbol +
                                String(now.getMinutes()).padStart(2, '0') + usymbol +
                                String(now.getSeconds()).padStart(2, '0')
            
            return `${text}_${formattedDate}.profile`
        }
        
        function exportProfile() {
            if (ios_platform) {
                let nameFile = nameExportedFileName(settingsPage.export_file_name)
                let data = extraChainController.exportedData()
                filePicker.pickFolderAndSaveFile(nameFile, data)
            } else if (android_platform) {
                let nameFile = nameExportedFileName(settingsPage.export_file_name)
                extraChainController.exportProfile("tmp", nameFile)
            } else {
                tempFolderDialog.currentFolder = QtCore.StandardPaths.standardLocations(QtCore.StandardPaths.HomeLocation)[0]
                tempFolderDialog.open()
            }
        }
        
        // Folder Dialog
        FolderDialog {
            id: tempFolderDialog
            currentFolder: QtCore.StandardPaths.standardLocations(QtCore.StandardPaths.HomeLocation)[0]
            onAccepted: {
                let path = Qt.resolvedUrl(tempFolderDialog.selectedFolder).toString()
                path = path.replace("file://", "")
                
                if (Qt.platform.os === "windows" && /^\/[A-Za-z]:/.test(path)) {
                    path = path.substring(1)
                }
                
                let nameFile = exportProfileButton.nameExportedFileName(exportProfileTf.text)
                extraChainController.exportProfile(path, nameFile)
                exportDialog.close()
            }
        }
        
        onClicked: {
            if(!exportDialog.is_new_version) {
                var nameFile = exportProfileButton.nameExportedFileName(exportProfileTf.text)
                if (ios_platform) {
                    let data = extraChainController.exportedData()
                    filePicker.pickFolderAndSaveFile(nameFile, data)
                } else if (android_platform) {
                    extraChainController.exportProfile("tmp", nameFile)
                } else {
                    tempFolderDialog.currentFolder =  QtCore.StandardPaths.standardLocations(QtCore.StandardPaths.HomeLocation)[0]
                    tempFolderDialog.open()
                }
            }
        }
    }

    Timer {
        id: showExportMessageTimer
        interval: 500
        onTriggered: {
            console.log("profile exported.")
            notificationToolTip.showMessage("Profile exported.")
        }
    }

    Connections {
        target: filePicker
        function onProfileExported() {
            showExportMessageTimer.restart()
        }
    }
    
    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
