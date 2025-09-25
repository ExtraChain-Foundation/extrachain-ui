import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"
import "../../"

Rectangle {
    id: withdrawRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.fill: parent
    // color: Colors.background
    color: Colors.deposit.background
    // border.color: Colors.border_color
    border.color: Colors.border_color
    border.width: isMobile ? 0 : 1
    radius: 8

    MouseArea { anchors.fill: parent }

    property string current_coin: "ExC"
    readonly property string _coin: selectCoinTF.currentCoin
    readonly property string _amount: amountTF.text
    property string _wallet_address: ""
    readonly property string _network: selectNetworkCB.currentText
    readonly property double percentFee: 0.5
    readonly property string _receive_address: withdrawalToTF.text
    property string availableBalance: Number(walletUIController?.estimatedBalance).toFixed(3)
    property int _height_element: 48
    signal next()

    Connections {
        target: root
        function onCurrentPageChanged() {
            loaderWithdrawal.visible = false
        }
    }

    ListModel {
        id: coinList

        ListElement {
            coin: "ExC"
            icon: "qrc:/images/UI/Images/raccoon.png"
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: cl.implicitHeight + 64
        clip: true
        boundsMovement: Flickable.StopAtBounds

        ColumnLayout {
            id: cl
            anchors.fill: parent
            anchors.topMargin: 30
            anchors.leftMargin: isMobile ? 16 : 50
            anchors.rightMargin: isMobile ? 16 : 50
            anchors.bottomMargin: 34
            spacing: 10

            BackButton {
                Layout.preferredWidth: 174
                Layout.preferredHeight: 46
                text: qsTr("Back to My wallet")
                onClickedBack: loaderWithdrawal.visible = false
            }

            RaccoonCoinComboBox {
                id: selectCoinTF
                Layout.fillWidth: true
                Layout.preferredHeight: _height_element
                model: coinList
                currentIcon: coinList.get(selectCoinTF.currentIndex).icon
                currentCoin: coinList.get(selectCoinTF.currentIndex).coin
                currentIndex: 0
                placeholderText: qsTr("Select coin")
                visible: false
            }

            RaccoonTextField {
                id: withdrawalToTF
                Layout.fillWidth: true
                Layout.preferredHeight: _height_element
                placeholderText: qsTr("Withdraw to")
                validator: RegularExpressionValidator {
                    regularExpression: /^[a-zA-Z0-9]{40}$/
                }

                onTextChanged: {
                    if(text.length === 40)
                        calcReceive()
                }
            }

            RaccoonTextField {
                id: amountTF
                Layout.fillWidth: true
                Layout.preferredHeight: _height_element
                useButtonMax: true
                coin_name: current_coin
                placeholderText: qsTr("Amount")
                validator: RegularExpressionValidator {
                    regularExpression: /^((0|[1-9][0-9]*))([.,][0-9]{1,3})?$/
                }

                onTextChanged: {
                    if (text.includes(",")) {
                        var newText = text.replace(",", ".")
                        text = newText
                        return
                    }

                    calcReceive()
                }

                onMax: {
                    console.log("pressed max", availableBalance)
                    text = parseFloat(availableBalance)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: walletList.contentHeight
                color: Colors.withdraw.wallet_list_background
                radius: 8

                ListView {
                    id: walletList
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    model: walletModel
                    spacing: 20
                    interactive: false
                    currentIndex: -1
                    header: Item {
                        width: ListView.view.width
                        height: 46
                        RowLayout {
                            anchors.fill: parent

                            DmsansText {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                color: Colors.def_color_text
                                verticalAlignment: Text.AlignVCenter
                                text: qsTr("Available")
                                font.pixelSize: 16
                                font.bold: true
                            }

                            DmsansText {
                                Layout.preferredWidth: paintedWidth
                                Layout.preferredHeight: 46
                                color: Colors.def_color_text
                                verticalAlignment: Text.AlignVCenter
                                text: availableBalance + " ExC"
                                font.pixelSize: 16
                                font.bold: true
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Colors.grape_gray_color
                            anchors.bottom: parent.bottom
                        }
                    }

                    delegate: MouseArea {
                        width: ListView.view.width
                        height: 46
                        onClicked: {
                            walletList.currentIndex = index
                            _wallet_address = wallet_id
                            availableBalance = Number(balance).toFixed(3)
                            calcReceive()
                            console.log("Selected", _wallet_address)
                        }

                        RowLayout {
                            anchors.fill: parent
                            spacing: 4

                            RaccoonCheckBox {
                                id: control
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: 20
                                Layout.maximumWidth: 20
                                checked: walletList.currentIndex === index
                                checkable: false
                                enabled: false
                                onClicked: {

                                }
                            }

                            MonserratText {
                                Layout.preferredHeight: 20
                                Layout.fillWidth: true
                                Layout.leftMargin: 12
                                text: name ? name : wallet_id
                                opacity: enabled ? 1.0 : 0.3
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 14
                                color: Colors.def_color_text
                                elide: Text.ElideRight
                            }

                            Item {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: 10
                            }

                            MonserratText {
                                Layout.preferredHeight: 20
                                Layout.preferredWidth: contentWidth
                                Layout.minimumWidth: contentWidth
                                clip: true
                                horizontalAlignment: Text.AlignRight
                                text: Number(balance).toFixed(3) + " ExC"
                                color: Colors.def_color_text
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight:68
                radius: 8
                color: Colors.withdraw.wallet_list_background

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        DmsansText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            text: qsTr("Receive amount")
                            color: Colors.withdraw.text
                            font.pixelSize: 16
                        }

                        DmsansText {
                            id: receiveAmountText
                            Layout.preferredWidth: paintedWidth
                            Layout.preferredHeight: 20
                            text:  "0 ExC"
                            color: Colors.withdraw.text
                            font.pixelSize: 16
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        DmsansText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            text: qsTr("Network fee")
                            color: Colors.grape_gray_color
                            font.pixelSize: 12
                        }

                        DmsansText {
                            Layout.preferredWidth: paintedWidth
                            Layout.preferredHeight: 20
                            text: "0 ExC"
                            color: Colors.grape_gray_color
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            Rectangle {
                id: withdrawBtn
                Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignRight
                Layout.maximumWidth: 364
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                color: enabled ? Colors.withdraw.enabled_button : Colors.withdraw.disabled_button
                radius: height/2
                enabled: fullFillIn()
                DmsansText {
                    anchors.centerIn: parent
                    text: qsTr("Send")
                    font.pixelSize: 16

                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        console.log("pressed `Send`")
                        console.log("You want send coins to", _receive_address)
                        console.log("amount", _amount)
                        if(ios_platform && appSettings.iosFaceIdPayment && faceIdAvailable) {
                            raccoonController.verifyWithFaceID();
                        } else {
                            send()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: raccoonController
        function onIosFaceAuth(result) {
            if(result && withdrawRoot.visible) {
                send()
            }
        }
    }

    function send() {
        raccoonController.sendTx(_wallet_address, _receive_address, _coin, _amount)
        clean()
        next()
    }

    MonserratText {
        id: tempDebug
        anchors.bottom: parent.bottom
        width: parent.width
        leftPadding: 6; rightPadding: 6
        wrapMode: Text.Wrap
        font.pixelSize: 11
        color: Colors.wallet_withdraw_page.tx_coin_and_value
        visible: UiSettings.debugMode
    }

    function fullFillIn() {
        const str = "Form validation check: " +
                  // "Coin selected: " + (selectCoinTF.currentIndex >= 0) +
                  " Addresses different: " + (_wallet_address != _receive_address) +
                  ", Wallet address valid: " + (_wallet_address.length !== 0) +
                  ", Receive address valid: " + (_receive_address.length !== 0) +
                  ", Withdrawal address length = 40: " + (withdrawalToTF.text.trim().length === 40) +
                  ", Wallet list not empty: " + (walletList.count > 0) +
                  ", Amount specified: " + (amountTF.text.trim().length > 0) +
                  ", Sufficient funds: " + (parseFloat(availableBalance) >= parseFloat(amountTF.text.trim())) +
                  ", Wallet selected: " + (walletList.currentIndex >= 0) +
                  ", Amount > 0: " + (Number(amountTF.text) !== 0) +
                  "<br>_wallet_address: " + _wallet_address +
                  "<br>_receive_address: " + _receive_address

        tempDebug.text = str

        return  _wallet_address != _receive_address
                && _wallet_address.length !== 0
                && _receive_address.length !== 0
                && withdrawalToTF.text.trim().length === 40
                && walletList.count > 0
                && amountTF.text.trim().length > 0
                && parseFloat(availableBalance) >= parseFloat(amountTF.text.trim())
                && walletList.currentIndex >= 0
                && Number(amountTF.text) !== 0
    }

    function calcFee(value) {
        return value;
    }

    function calc(value) {
        return value - calcFee(value)
    }

    function calcReceive() {
        if(_wallet_address === withdrawalToTF.text) {
            notificationToolTip.showMessage(qsTr("You’re trying to send funds to the same wallet"))
            return;
        }

        var amount = Number(amountTF.text)
        var ab = parseInt(availableBalance)
        console.log(ab, amount)

        if(isNaN(amount)) {
            console.log("amount is NAN")
            return 0;
        }

        if(ab === 0 || amount === 0) {
            receiveAmountText.text = 0
            return 0;
        }
        var calcReceiveValue = (ab - amount)
        if(Number.isNaN(calcReceiveValue)) {
            receiveAmountText.text = 0
            return 0
        }

        if(calcReceiveValue < 0) {
            receiveAmountText.text = parseFloat(calcReceiveValue.toFixed(3))
            amountTF.error_border_width = 1
            return
        }

        console.log("[amount]", amount)
        receiveAmountText.text = amount + " ExC"
    }

    function clean() {
        walletList.currentIndex = -1
        withdrawalToTF.text = ""
        amountTF.text = ""
    }
}
