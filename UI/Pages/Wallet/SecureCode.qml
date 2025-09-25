import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"

Rectangle {
    id: secureCodeRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.fill: parent

    color: Colors.wallet_withdraw_page.background

    signal nextSecureCode

    MouseArea { anchors.fill: parent }

    BackButton {
        onClickedBack: {
            secureCodeRoot.visible = false
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        MonserratText {
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: paintedWidth
            text: qsTr("Enter your secure code to proceed")
            font.pixelSize: 16
            color: Colors.createWalletPage.title_text
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            Layout.preferredWidth: 1
        }

        MonserratText {
            Layout.preferredHeight: 25
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 360
            text: qsTr("Code")
            font.pixelSize: 14
            color: Colors.createWalletPage.text
        }

        ExTextField {
            Layout.preferredHeight: 40
            Layout.preferredWidth: 360
            placeholderText: qsTr("Enter code")
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            Layout.preferredWidth: 1
        }

        ExButton {
            id: depositBtn
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            text: qsTr("Create")
            style: Colors.button_deposit_style
            onClicked: {
                console.log("pressed create.")
                nextSecureCode();
            }
        }
    }
}
