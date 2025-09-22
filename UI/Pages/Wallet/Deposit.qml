import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"
import "../../"

Rectangle {
    id: depositRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.fill: parent
    // color: Colors.background
    color: Colors.background
    border.color: Colors.border_color
    border.width: isMobile ? 0 : 1
    radius: 8

    // MouseArea { anchors.fill: parent }

    property string current_coin: "ExC"

    readonly property string _coin: selectCoinTF.currentCoin
    readonly property string _address: addressTF.text
    // readonly property string _wallet_address: selectNetworkCB.currentText
    // readonly property string _network: selectNetworkCB.currentText
    readonly property double percentFee: 0.5
    property string selected_wallet_id

    onVisibleChanged: {
        console.log("cscsdcdscdsc", visible, selectWalletCB.model.count, appSettings.depositSelectedWalletIndex)
        if(visible && selectWalletCB.model.count > appSettings.depositSelectedWalletIndex) {
            selectWalletCB.currentIndex = appSettings.depositSelectedWalletIndex
        }
    }

    Connections {
        target: root
        function onSellected_windowChanged() {
            loaderWithdrawal.visible = false
        }
    }

    ColumnLayout {
        id: cl
        anchors.fill: parent
        anchors.topMargin: 30
        anchors.leftMargin: isMobile ? 5 : 0
        anchors.rightMargin: isMobile ? 5 : 0
        anchors.bottomMargin: 34
        spacing: 10

        BackButton {
            Layout.preferredWidth: 174
            Layout.preferredHeight: 46
            text: "Back to My wallet"
            onClickedBack: loaderWithdrawal.visible = false
        }

        Rectangle {
            Layout.preferredWidth: 174
            Layout.preferredHeight: 174
            Layout.alignment: Qt.AlignHCenter
            radius: 8
            visible: selectWalletCB.currentText!== '' && selectWalletCB.currentIndex !== -1

            Image {
                id: qrImage
                anchors.fill: parent
                anchors.margins: 10
                cache: false
                sourceSize.width: width; sourceSize.height: height
                source: 'image://QZXing/encode/RLW:' + selectWalletCB.currentText
            }
        }

        Item {
            Layout.preferredHeight: 6
            Layout.fillWidth: true
        }

        ComboBox {
            id: selectWalletCB
            Layout.maximumWidth: isMobile ? 364 : 400
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 44
            model: walletModel
            currentIndex: -1
            textRole: selected_role//"wallet_id"
            property string selected_role: "name"
            onCurrentIndexChanged: {
                selected_wallet_id = walletModel.get(currentIndex).wallet_id
                if(walletModel.get(currentIndex).name.length > 0) {
                    selectWalletCB.selected_role = "name"
                } else {
                    selectWalletCB.selected_role = "wallet_id"
                }

                if(currentIndex >= 0)
                    appSettings.depositSelectedWalletIndex = currentIndex
            }

            delegate: ItemDelegate {
                width: selectWalletCB.width
                height: selectWalletCB.height

                contentItem: DmsansText {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 12
                    rightPadding: selectWalletCB.indicator.width + selectWalletCB.spacing
                    text: model.name ? model.name : model.wallet_id
                    font: selectWalletCB.font
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                highlighted: selectWalletCB.highlightedIndex === index
            }

            indicator: Item {
                x: selectWalletCB.width - width - selectWalletCB.rightPadding
                y: selectWalletCB.topPadding + (selectWalletCB.availableHeight - height) / 2
                width: 12
                height: 8

                IconText {
                    anchors.centerIn: parent
                    text: IcoMoon.down
                    color: Colors.raccoonComboBoxDefaultStyle.selected_text
                }
            }

            contentItem: DmsansText {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 15
                rightPadding: 15
                text: selectWalletCB.currentText
                font: selectWalletCB.font
                color: Colors.raccoonComboBoxDefaultStyle.selected_text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                height: 48
                width: selectWalletCB.width
                radius: 8
                color: Colors.background
                border.width: 1
                border.color: Colors.border_color
                Rectangle {
                    color:Colors.background
                    anchors.verticalCenter: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    height: 16
                    width: placeholder.paintedWidth + 8
                    DmsansText {
                        id: placeholder
                        text: "Deposit Address"
                        font.pixelSize: 12
                        color: Colors.grape_gray_color
                        leftPadding: 4
                    }
                }
            }

            popup: Popup {
                y: selectWalletCB.height - 1
                width: selectWalletCB.width
                implicitHeight: contentItem.implicitHeight
                padding: 1

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: selectWalletCB.popup.visible ? selectWalletCB.delegateModel : null
                    currentIndex: selectWalletCB.highlightedIndex

                    ScrollIndicator.vertical: ScrollIndicator { }
                }

                background: Rectangle {
                    radius: 12
                    color: Colors.raccoonComboBoxDefaultStyle.background
                }
            }
        }

        Rectangle {
            Layout.maximumWidth: isMobile ? 364 : 400
            Layout.minimumWidth: isMobile ? 364 : 400

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 188
            color: Colors.background
            border.color: Colors.border_color
            border.width: 1
            radius: 8

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 20
                anchors.bottomMargin: 20
                spacing: 15

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    color: Colors.grape_gray_color
                    font.pixelSize: 12
                    text: "Network"
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    text: "ROCC     Network"
                }


                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    color: Colors.grape_gray_color
                    font.pixelSize: 12
                    text: "Deposit Address"
                }

                MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    onClicked: {
                        walletUIController.copyWalletAddress(selected_wallet_id)
                        notificationToolTip.message = "You copied wallet address "
                                + selected_wallet_id + "."
                        notificationToolTip.showMessage("ADDRESS COPIED TO CLIPBOARD", Tooltip.CopiedAddress)
                    }
                    enabled: selectWalletCB.currentIndex >= 0


                    RowLayout {
                        anchors.fill: parent
                        DmsansText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            color: Colors.def_color_text
                            font.pixelSize: 16
                            text: selected_wallet_id ? selected_wallet_id : "-"
                            elide: Text.ElideRight
                        }

                        IconText {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            text: IcoMoon.copy
                            color: Colors.def_color_text
                            opacity: selectWalletCB.currentIndex >= 0 ? 1.0 : 0.7
                            font.pixelSize: 20
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 2
        }

        Rectangle {
            id: depositBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 364
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: enabled ? Colors.deposit.enabled : Colors.deposit.disabled
            radius: height/2


            DmsansText {
                anchors.centerIn: parent
                text: qsTr("Save and Share Address")
                font.pixelSize: 16
            }
            enabled: selectWalletCB.currentIndex >= 0

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    console.log("pressed back")
                    walletUIController.copyWalletAddress(selectWalletCB.currentText)
                    notificationToolTip.message = "You copied wallet address "
                            + selectWalletCB.currentText + "."
                    notificationToolTip.showMessage("ADDRESS COPIED TO CLIPBOARD", Tooltip.CopiedAddress)
                    loaderWithdrawal.visible = false
                }
            }
        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
        }
    }

    function fullFillIn() {
        console.log(selectCoinTF.currentIndex <= 0, addressTF.text.trim().length > 0, _wallet_address.length === 40)
        return selectCoinTF.currentIndex <= 0 && addressTF.text.trim().length > 0 && _wallet_address.length === 40
    }

    function calcFee(value) {
        return ((value*percentFee)/100)
    }

    function calc(value) {
        return value - calcFee(value)
    }

    function clear() {
        addressTF.text = ""
        depositToTF.text = ""
    }
}
