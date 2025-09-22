import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"
import "../.."

RaccoonPage {
    id: createWalletRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.fill: parent

    // color: Colors.wallet_withdraw_page.background

    signal back()
    signal nextWallet(var name_wallet, var coin_name)

    MouseArea { anchors.fill: parent }

    BackButton {
        id: backToWallet
        y: ios_platform || android_platform ? 50 : 0
        onClickedBack: {
            back()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        DmsansText {
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: paintedWidth
            text: qsTr("Create new wallet")
            font.pixelSize: 16
            color: Colors.createWalletPage.title_text
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 20
            Layout.preferredWidth: 1
        }

        // MonserratText {
        //     Layout.preferredHeight: 25
        //     Layout.alignment: Qt.AlignLeft
        //     Layout.preferredWidth: 360
        //     text: qsTr("Wallet name")
        //     font.pixelSize: 14
        //     color: Colors.createWalletPage.text
        // }

        RaccoonTextField {
            id: nameWalletTF
            Layout.preferredHeight: visible ? 40 : 0
            Layout.preferredWidth: 360
            placeholderText: qsTr("Wallet name") + " (" + qsTr("optional") + ")"
            visible: !isNewProfile
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 20 : 0
            Layout.preferredWidth: 1
            visible: !isNewProfile
        }

        ListModel {
            id: coinList

            ListElement {
                coin: "ExC"
                icon: "qrc:/images/UI/Images/raccoon.png"
            }
        }

        RaccoonCoinComboBox {
            id: selectCoinCB
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 360
            model: coinList
            currentIcon: coinList.get(currentIndex).icon
            currentCoin: coinList.get(currentIndex).coin
            placeholderText: "Wallet coin"
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40
            Layout.preferredWidth: 1
        }

        BlueButton {
            id: depositBtn
            Layout.preferredHeight: 50
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 360
            text: qsTr("Create")
            filled: true
            onClicked: {
                console.log("pressed create.")
                var nameWallet = nameWalletTF.text
                raccoonController.addNewWallet(nameWallet)
            }
        }
    }
}
