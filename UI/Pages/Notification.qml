import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0
import QtQml.Models

import "../Fonts"
import "../Controls"
import "../"

Rectangle {
    id: notificationPage
    visible: root.sellected_window === MenuSelector.Notification && isMobile
    anchors.fill: parent
    color: Colors.notificationPopup.background

    property int detail_type
    property string detail_amount
    property string detail_address
    property string detail_time_date


    RowLayout {
        id: rwMobileTitle
        anchors.topMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: visible ? 56 : 0
        visible: isMobile

        Image {
            Layout.preferredHeight: 24
            Layout.preferredWidth: 157
            Layout.alignment: Qt.AlignVCenter
            antialiasing: true
            source: Colors.logo_and_text
        }

        Item {
            Layout.preferredHeight: 40
            Layout.fillWidth: true
        }

        Item {
            Layout.preferredHeight: 48
            Layout.preferredWidth: 104
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                id: maNotifications
                anchors.left: parent.left
                anchors.right: parent.horizontalCenter
                height: parent.height
                property int saved_previous_window

                Rectangle {
                    height: parent.height
                    width: height
                    radius: height/2
                    color: Colors.mobile_notification_settings_box
                    border.color: Colors.notification.border_color
                    border.width: 1

                    IconText {
                        anchors.centerIn: parent
                        text: IcoMoon.bell
                        color: Colors.notification.icon
                        font.pixelSize: 22
                        opacity: parent.pressed ? 0.8 : 1.0
                    }
                }

                Connections {
                    target: root
                    onSellected_windowChanged: {
                        if(root.sellected_window !== MenuSelector.Notification) {
                            maNotifications.saved_previous_window = root.sellected_window
                        }
                    }
                }

                onClicked: {
                    if(root.sellected_window === MenuSelector.Notification) {
                        if(saved_previous_window === MenuSelector.Vpn)
                            root.sellected_window = MenuSelector.Vpn
                        else if(saved_previous_window === MenuSelector.Wallet)
                            root.sellected_window = MenuSelector.Wallet
                        else if(saved_previous_window === MenuSelector.Locations)
                            root.sellected_window = MenuSelector.Locations
                        else if(saved_previous_window === MenuSelector.Notification)
                            root.sellected_window = MenuSelector.Notification
                        else if(saved_previous_window === MenuSelector.Dfs)
                            root.sellected_window = MenuSelector.Dfs
                        else
                            root.sellected_window = MenuSelector.Vpn
                    }
                }
            }

            MouseArea {
                anchors.left: parent.horizontalCenter
                anchors.right: parent.right
                height: parent.height
                property int saved_previous_window

                Rectangle {
                    height: parent.height
                    width: height
                    radius: height/2
                    color: Colors.mobile_notification_settings_box

                    IconText {
                        anchors.centerIn: parent
                        text: IcoMoon.settings
                        font.pixelSize: 22
                        opacity: parent.pressed ? 0.8 : 1.0
                        color: Colors.mobile_notification_settings_text
                    }
                }

                onClicked: {
                    root.sellected_window = MenuSelector.Settings
                }
            }
        }
    }

    StackView {
        id: stackview
        anchors.fill: parent
        anchors.topMargin: rwMobileTitle.height
        anchors.leftMargin: isMobile ? 10 : 18
        anchors.rightMargin: isMobile ? 10 : 18
        initialItem: mainView
    }

    Component {
        id: mainView

        ColumnLayout {
            spacing: 28

            SquareButton {
                Layout.alignment: Qt.AlignRight
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                Layout.maximumHeight: 24
                style: Colors.wallet_withdraw_page.button_back_style
                size: parent.width
                icon: IcoMoon.close
                koef_icon_size: 1.0
                rotation: 90
                visible: !isMobile

                onClicked: {
                    notificationPopup.close()
                }
            }

            RowLayout {
                Layout.alignment: isMobile ? Qt.AlignLeft : Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.rightMargin: isMobile ? 10 : 18
                Layout.leftMargin: isMobile ? 10 : 18

                Layout.preferredHeight: 24
                Layout.maximumHeight: 24

                Item {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    visible: isMobile

                    SquareButton {
                        anchors.fill: parent
                        style: Colors.wallet_withdraw_page.button_back_style
                        icon: IcoMoon.down
                        koef_icon_size: 1.0
                        rotation: 90

                        onClicked: {
                            maNotifications.clicked(maNotifications)
                        }
                    }
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.maximumHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: isMobile ? Text.AlignLeft : Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "Notification"
                    color:  Colors.def_color_text
                    font.pixelSize: isMobile ? 24 : 18
                    font.bold: true
                }
            }

            RaccoonTextField {
                id: searchTf
                Layout.fillWidth: true
                Layout.leftMargin: isMobile ? 10 : 18
                Layout.rightMargin: isMobile ? 10 : 18
                Layout.preferredHeight: isMobile ? 48 : 40
                placeholderText: "Search"
                useSearchIcon: true
                visible: false//listNotifications.model.count > 0
                enabled: false
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                visible: listNotifications?.model?.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    height: 50
                    width: dnanText.paintedWidth
                    IconText {
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: Colors.grape_gray_color
                        font.pixelSize: 24
                        text: IcoMoon.bell
                    }

                    DmsansText {
                        id: dnanText
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: paintedWidth
                        text: "You don't have any notifications"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.weight: 500
                        color: Colors.grape_gray_color
                    }
                }
            }

            ListView {
                id: listNotifications
                Layout.fillHeight: true
                Layout.fillWidth: true
                model: notificationController
                clip: true
                visible: count > 0
                spacing: 10
                delegate: Item {
                    id: delegate
                    width: ListView.view.width
                    height: !dateText.visible ? (isMobile ? 80 : 65) : (isMobile ? 106 : 81)

                    function isShowDate() {
                        if( listNotifications.model.get(index-1).date === "undefined")
                            return true

                        if(listNotifications.model.get(index-1).date === model.date) {
                            return false
                        } else {
                            return true
                        }
                    }

                    ColumnLayout {
                        id: clNotification
                        anchors.fill: parent
                        anchors.verticalCenter: parent.verticalCenter

                        DmsansText {
                            id: dateText
                            Layout.fillWidth: true
                            Layout.preferredHeight: visible ? 16 : 0
                            visible: delegate.isShowDate()
                            text:  model.is_today ? "Today" : model.date
                            leftPadding: isMobile ? 16 : 30
                            color: Colors.grape_gray_color
                            font.pixelSize: 14
                        }

                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            color: listNotifications.currentIndex === index ? Colors.notification.selected : Colors.notification.unselected

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: isMobile ? 16 : 30
                                anchors.rightMargin: isMobile ? 16 : 30
                                anchors.topMargin: isMobile ? 16 : 14
                                anchors.bottomMargin: isMobile ? 16 : 14
                                Rectangle {
                                    Layout.preferredHeight: isMobile ? 48 : 36
                                    Layout.preferredWidth:  Layout.preferredHeight
                                    color: listNotifications.currentIndex === index ? Colors.notification.placeholder_icon_selected
                                                                                    : Colors.notification.placeholder_icon_unselected
                                    radius: height/2

                                    Image {
                                        anchors.centerIn: parent
                                        source: (() => {
                                                     switch(model.type) {
                                                         case 0: return "qrc:/new_design/UI/Images/new_design/deposited.svg"
                                                         case 1: return "qrc:/new_design/UI/Images/new_design/withdraw.svg"
                                                         case 2: return "qrc:/new_design/UI/Images/new_design/rewards.svg"
                                                     }
                                                 })()
                                        antialiasing: true
                                        smooth: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredHeight: implicitHeight
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 0

                                    DmsansText {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: paintedHeight
                                        color: Colors.grape_gray_color
                                        text: (() => {
                                                   switch(model.type) {
                                                       case 0: return "Deposited"
                                                       case 1: return "Withdraw"
                                                       case 2: return "Mining reward"
                                                   }
                                               })()
                                        font.pixelSize: 14
                                    }

                                    DmsansText {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: paintedHeight
                                        text: (type === 1 ? "-" : "+") + model.amount + " ExC"
                                        color: listNotifications.currentIndex === index ? Colors.notification.amount_selected : Colors.notification.amount_unselected
                                        font.pixelSize: 16
                                    }
                                }

                                DmsansText {
                                    Layout.preferredWidth: paintedWidth
                                    Layout.preferredHeight: paintedHeight
                                    Layout.alignment: Qt.AlignVCenter
                                    text: model.time
                                    color: Colors.notification.time
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            listNotifications.currentIndex = index
                            detail_type = model.type
                            detail_amount = model.amount
                            detail_address = model.type === 1 ? model.receiver : model.sender
                            detail_time_date = model.time_date
                            stackview.push(detailsComponent)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: detailsComponent

        ColumnLayout {
            anchors.fill: parent
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 64 : 0
                Layout.maximumHeight: 64
                SquareButton {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 32
                    Layout.alignment: Qt.AlignVCenter
                    menu_button: true
                    icon: IcoMoon.down
                    rotation: 90
                    onClicked: {
                        stackview.pop()
                    }
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    text: "Details"
                    font.pixelSize: 24
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.weight: 600
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: 48
                Layout.alignment: Qt.AlignHCenter
                color: Colors.notification.detail_placeholder_icon
                border.width: 1
                border.color: Colors.notification.detail_placeholder_border_color
                radius: height/2

                Image {
                    anchors.centerIn: parent
                    source: (() => {
                                 switch(detail_type) {
                                     case 0: return "qrc:/new_design/UI/Images/new_design/deposited.svg"
                                     case 1: return "qrc:/new_design/UI/Images/new_design/withdraw.svg"
                                     case 2: return "qrc:/new_design/UI/Images/new_design/rewards.svg"
                                 }
                             })()
                    antialiasing: true
                    smooth: true
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight

                DmsansText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: paintedHeight
                    text: (detail_type === 1 ? "-" : "+") + detail_amount + " ExC"
                    color: Colors.def_color_text
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 28
                    font.weight: 600
                }


                DmsansText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: paintedHeight
                    text: detail_time_date
                    font.pixelSize: 14
                    font.weight: 600
                    color: Colors.grape_gray_color
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 128

                RowLayout {
                    width: parent.width - (isMobile ? 28 : 60)
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 64
                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.grape_gray_color
                        font.pixelSize: 16
                        text: "Address"
                    }

                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.def_color_text
                        font.pixelSize: 16
                        text: detail_address
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        font.weight: 600
                    }

                    IconText {
                        Layout.preferredHeight: 64
                        Layout.preferredWidth: 30
                        text: IcoMoon.copy
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.def_color_text
                        font.pixelSize: 20
                        font.weight: 400

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(detail_address)
                                notificationToolTip.showMessage("ADDRESS COPIED TO CLIPBOARD", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                Rectangle {
                    height: 1
                    width: parent.width - (isMobile ? 28 : 60)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Colors.grape_gray_color
                }

                RowLayout {
                    width: parent.width - (isMobile ? 28 : 60)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    height: 64
                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.grape_gray_color
                        font.pixelSize: 16
                        text: "Deposit Wallet"
                    }

                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.grape_gray_color
                        font.pixelSize: 16
                        text: "Spot Wallet"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        font.weight: 600
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
