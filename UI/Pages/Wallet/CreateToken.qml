import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"

Rectangle {
    id: depositRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.fill: parent
    color: Colors.wallet_withdraw_page.background
    property string rulling_address

    MouseArea { anchors.fill: parent }

    BackButton {
        id: backToWallet

        onClickedBack: {
            loaderWithdrawal.visible = false
        }
    }



    ColumnLayout {
        anchors.centerIn: parent

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            MonserratText {
                anchors.right: nameTokenTF.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                text: qsTr("Name token")
                color: Colors.wallet_withdraw_page.color_text
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            RaccoonTextField {
                id: nameTokenTF
                anchors.centerIn: parent
                height: 40
                width: 360
                placeholderText: qsTr('Set name token')
                activeFocusOnTab: true
                useButtonMax: false
                onTextChanged: {
                    if (text.length > 0 && text.startsWith("0")) {
                        text = "";
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            MonserratText {
                anchors.right: symbolTokenTF.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                text: qsTr("Symbol")
                color: Colors.wallet_withdraw_page.color_text
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            RaccoonTextField {
                id: symbolTokenTF
                anchors.centerIn: parent
                height: 40
                width: 360
                placeholderText: qsTr('Set token symbol')
                useButtonMax: false
                activeFocusOnTab: true
                validator: RegularExpressionValidator {
                    regularExpression: /^[a-zA-Z]{3,4}$/
                }
                onTextChanged: {
                    if (text.length > 0 && text.startsWith("0")) {
                        text = "";
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46

            MonserratText {
                anchors.right: amountTF.right
                anchors.verticalCenter: parent.verticalCenter
                height: 36
                text: qsTr("Count tokens")
                color: Colors.wallet_withdraw_page.color_text
                font.pixelSize: 14
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            RaccoonTextField {
                id: countTokensTF
                anchors.centerIn: parent
                height: 40
                width: 360
                placeholderText: qsTr('Set count tokens')
                useButtonMax: false
                validator: RegularExpressionValidator {
                    regularExpression: /^[1-9][0-9]*$/
                }

                onTextChanged: {
                    if (text.length > 0 && text.startsWith("0")) {
                        text = "";
                    }
                }
            }
        }

        MonserratText {
            Layout.preferredWidth: 360
            Layout.minimumHeight: 40
            text: "Rulling address"
            color: Colors.wallet_withdraw_page.color_text
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 360
            Layout.preferredHeight: 140
            radius: 12
            color: Colors.wallet_withdraw_page.background_list_view

            ListView {
                id: walletList
                anchors.fill: parent
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                model: walletModel
                clip: true
                spacing: 12
                onVisibleChanged: {
                    rulling_address = model.get(0).wallet
                }

                delegate: MouseArea {
                    width: 328
                    height: 21

                    onClicked: {
                        console.log("clicked")
                        walletList.currentIndex = index
                        rulling_address = wallet
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 4

                        RaccoonCheckBox {
                            id: control
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 22
                            Layout.maximumWidth: 22
                            unchecked: Colors.wallet_withdraw_page.uncheckBackground
                            checked: walletList.currentIndex === index
                            checkable: false
                        }

                        MonserratText {
                            Layout.preferredHeight: 22
                            Layout.fillWidth: true
                            text: wallet
                            opacity: enabled ? 1.0 : 0.3
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            color: Colors.wallet_withdraw_page.tx_coin_and_value
                            elide: Text.ElideRight
                        }

                        Item {
                            Layout.preferredHeight: 21
                            Layout.preferredWidth: 10
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredWidth: 360
            Layout.minimumHeight: 100

            Rectangle {
                id: tokenColorBox
                anchors.centerIn: parent
                height: parent.height
                width: height
                radius: height/2
                color: generateRandomColor()

                MonserratText {
                    anchors.centerIn: parent
                    text: "T"
                    color: "white"
                    font.pixelSize: 30
                    font.bold: true
                    font.italic: true
                }
            }
        }

        RaccoonButton {
            id: generateTokenColorButton
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 46
            Layout.preferredWidth: 360
            Layout.minimumWidth: 360

            text: qsTr("Generate color")
            style: Colors.button_deposit_style_old
            onClicked: {
                console.log("start generate color")
                var generatedColor = generateRandomColor()
                console.log("generated color ", generatedColor)
                tokenColorBox.color = generatedColor
            }
        }

        RaccoonButton {
            id: generateToken
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 46
            Layout.preferredWidth: 360
            Layout.minimumWidth: 360

            text: qsTr("Generate token")
            style: Colors.button_deposit_style_old
            enabled: fullFillIn()
            onClicked: {
                const tokenCount = countTokensTF.text.trim();
                const tokenName = nameTokenTF.text.trim();
                const tokenColor = tokenColorBox.color;
                const tokenSymbol = symbolTokenTF.text.trim()

                console.log("start generate token")
                console.log("rulling address ", rulling_address)
                console.log("Name token - ", tokenName)
                console.log("Count token - ", tokenCount)
                console.log("Color token ", tokenColor)
                console.log("Color token ", tokenSymbol)
                raccoonController.createToken(tokenCount, tokenName, tokenSymbol, rulling_address, tokenColor)
            }
        }
    }

    function generateRandomColor() {
        let randomColor = Math.floor(Math.random() * 16777215).toString(16);
        return "#" + randomColor.padStart(6, '0');
    }

    function fullFillIn() {
        const isRulingAddressValid = rulling_address.length > 0;
        const isNameTokenValid = nameTokenTF.text.trim().length > 0;
        const isCountTokensValid = countTokensTF.text.trim().length > 0;
        const isTokenSymbolValid = symbolTokenTF.text.trim().length > 2;

        console.log(isRulingAddressValid, isNameTokenValid, isCountTokensValid);

        return isRulingAddressValid && isNameTokenValid && isCountTokensValid && isTokenSymbolValid;
    }

    function clean() {
        nameTokenTF.text = ""
        countTokensTF.text = ""
        symbolTokenTF.text = ""
        generateRandomColor()
    }

    Connections {
        target: raccoonController

        function onAddedToken() {
            loaderWithdrawal.visible = false
            clean()
        }

        function onErrorNameTokenExist(nameToken) {
            nameTokenTF.focus = true
            nameTokenTF.forceActiveFocus()
        }

        function onErrorSymbolTokenExist(symbolToken) {
            symbolTokenTF.focus = true
            symbolTokenTF.forceActiveFocus()
        }
    }
}
