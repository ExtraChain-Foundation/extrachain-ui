import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import QtCore
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

ExPage {
    id: exportPage
    visible: false
    readonly property alias export_file_name: namefileTF.text

    onVisibleChanged: {
        if (!logined) visible = false
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width- 100
        height: implicitHeight
        spacing: 30

        MonserratText {
            Layout.preferredWidth: paintedWidth
            Layout.preferredHeight: paintedHeight
            Layout.maximumWidth: parent.width
            Layout.alignment: Qt.AlignHCenter
            text: "For safe usage and easier restoration of your wallet, please export your profile and save it at reliable place:"
            color: Colors.def_color_text
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 18
            font.bold: true
        }

        ExTextField {
            id: namefileTF
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignHCenter
            font.family: Montserrat.dmsans
            font.pointSize: 12
            focus: false
            placeholderText: "File name"
            text: "ExtraChain"
            validator: RegularExpressionValidator {
                regularExpression: /^[a-zA-Z0-9]+$/
            }
        }

        BlueButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            Layout.preferredWidth: 130
            text: "Export Profile..."
            filled: true
            onClicked: {
                console.log("[new version] Press exprt profile")
                exportProfile()
                exportPage.visible = false
            }
        }

        MouseArea {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            Layout.preferredWidth: 130

            MonserratText {
                anchors.centerIn: parent
                text: "Skip>"
                color: Colors.export_page.text
                opacity: parent.pressed ? 0.7 : 1.0
            }

            onClicked: {
                console.log("pressed skip")
                exportPage.visible = false
            }
        }
    }

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
            let nameFile = nameExportedFileName(export_file_name)
            let data = extraChainController.exportedData()
            filePicker.pickFolderAndSaveFile(nameFile, data)
        } else if (android_platform) {
            let nameFile = nameExportedFileName(export_file_name)
            extraChainController.exportProfile("tmp", "ExtraChain"/*nameFile*/)
        } else {
            tempFolderDialog.currentFolder = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
            tempFolderDialog.open()
        }
    }

    FolderDialog {
        id: tempFolderDialog
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            let path = Qt.resolvedUrl(tempFolderDialog.selectedFolder).toString()
            path = path.replace("file://", "")

            if (Qt.platform.os === "windows" && /^\/[A-Za-z]:/.test(path)) {
                path = path.substring(1)
            }

            let nameFile = nameExportedFileName(export_file_name)
            extraChainController.exportProfile(path, nameFile)
        }
    }
}
