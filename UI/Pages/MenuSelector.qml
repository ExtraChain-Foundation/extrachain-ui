import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"

Rectangle {
    id: menu
    color: Colors.menu_selector.background
    radius: 8
    z: 1
    border.width: 1
    border.color: Colors.border_color

    Rectangle {
        width: parent.width
        height: parent.radius
        color: parent.color
        visible: isMobile
    }

    ColumnLayout {
        id: menuCl
        anchors.fill: parent
        anchors.topMargin: 20
        anchors.bottomMargin: 20
        visible: isDesktop
        spacing: 6
        enabled: appSettings.onboard_finished

        SquareButton {
            id: walletPageBtn
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            text: qsTr("Wallet")
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.wallet
            selected: currentPage === MenuSelector.Wallet || onboarding_current_page === Onboarding.Wallet_Access
            menu_button: true
            onClicked: { currentPage = MenuSelector.Wallet; walletPageBtn.selected = true }

        }

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            text: qsTr("Storage")
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.storage
            selected: currentPage === MenuSelector.Dfs
            menu_button: true
            onClicked: { currentPage = MenuSelector.Dfs; walletPageBtn.selected = false }
        }

        Item { Layout.fillHeight: true }  // Spacer

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            Layout.bottomMargin: 3
            text: qsTr("Alerts")
            icon: IcoMoon.bell
            style: Colors.button_menu_square_default_style
            menu_button: true
            selected: false || onboarding_current_page === Onboarding.Notifications_And_Settings
                      || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
            onClicked: {
                notificationPopup.open()
            }
        }

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            Layout.bottomMargin: 3
            text: qsTr("Settings")
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.settings
            selected: false || onboarding_current_page === Onboarding.Notifications_And_Settings
                      || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
            menu_button: true
            onClicked: {
                settingsPopup.open()
            }
        }

        Image {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignHCenter
            antialiasing: true
            source: "qrc:/UI/Images/extrachain_lite.png"
        }
    }

    Item {
        id: menuRl
        anchors.fill: parent
        visible: root.isMobile

        ColumnLayout {
            anchors.fill: parent
            enabled: appSettings.onboard_finished

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true

                RowLayout {
                    anchors.fill: parent

                    SquareButton {
                        id: walletBtn
                        Layout.fillHeight: true
                        Layout.preferredWidth: menuRl.height
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.wallet
                        selected:  currentPage === MenuSelector.Wallet || onboarding_current_page === Onboarding.Wallet_Access
                        onClicked: {
                            if(currentPage !== MenuSelector.Wallet) {
                                currentPage = MenuSelector.Wallet
                                selected = true
                            }
                        }
                        text: qsTr("Wallet")
                        style: Colors.button_menu_square_default_style
                        menu_button: true

                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    SquareButton {
                        Layout.fillHeight: true
                        Layout.preferredWidth: menuRl.height
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.storage
                        selected: currentPage === MenuSelector.Dfs
                        text: qsTr("Storage")
                        style: Colors.button_menu_square_default_style
                        menu_button: true
                        onClicked: { currentPage = MenuSelector.Dfs; walletBtn.selected = false }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    SquareButton {
                        Layout.fillHeight: true
                        Layout.preferredWidth: menuRl.height
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.bell
                        selected: currentPage === MenuSelector.Notification || onboarding_current_page === Onboarding.Notifications_And_Settings
                                  || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
                        text: qsTr("Alert")
                        style: Colors.button_menu_square_default_style
                        menu_button: true
                        onClicked: { currentPage = MenuSelector.Notification;  walletBtn.selected = false }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    SquareButton {
                        Layout.fillHeight: true
                        Layout.preferredWidth: menuRl.height
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.settings
                        selected: currentPage === MenuSelector.Settings || onboarding_current_page === Onboarding.Notifications_And_Settings
                                  || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
                        text: qsTr("Settings")
                        style: Colors.button_menu_square_default_style
                        menu_button: true
                        onClicked: { currentPage = MenuSelector.Settings; walletBtn.selected = false }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 0
                visible: false
            }
        }
    }

    states: [
        State {
            name: "if_not_mobile"
            when: isDesktop
            PropertyChanges { target: menu; Layout.fillHeight: true; Layout.preferredWidth: 64 }
        },
        State {
            name: "if_mobile"
            when: isMobile
            PropertyChanges { target: menu; Layout.fillWidth: true; Layout.preferredHeight: 64 }
        }
    ]
}
