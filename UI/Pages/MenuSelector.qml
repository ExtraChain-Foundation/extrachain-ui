import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"

Rectangle {
    id: menu
    color: Colors.menu_selector.background
    radius: 16
    z: 1
    border.width: 1
    border.color: Colors.menu_selector.border_color

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
        visible: !root.isMobile
        spacing: 6
        enabled: appSettings.onboard_finished

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            text: "Storage"
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.storage
            selected: root.sellected_window === MenuSelector.Dfs
            menu_button: true
            onClicked: root.sellected_window = MenuSelector.Dfs
        }

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            text: "Wallet"
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.wallet
            selected: root.sellected_window === MenuSelector.Wallet || onboarding_current_page === Onboarding.Wallet_Access
            menu_button: true
            onClicked: root.sellected_window = MenuSelector.Wallet
        }


        Item { Layout.fillHeight: true }  // Spacer

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            Layout.bottomMargin: 3
            text: "Alerts"
            icon: IcoMoon.bell
            style: Colors.button_menu_square_default_style
            menu_button: true
            selected: false || onboarding_current_page === Onboarding.Notifications_And_Settings || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
            onClicked: {
                notificationPopup.open()
            }
        }

        SquareButton {
            Layout.fillWidth: true
            Layout.preferredHeight: menuCl.width
            Layout.bottomMargin: 3
            text: "Settings"
            style: Colors.button_menu_square_default_style
            icon: IcoMoon.settings
            selected: false || onboarding_current_page === Onboarding.Notifications_And_Settings || onboarding_current_page === Onboarding.Storage_Notification_and_Settings
            menu_button: true
            onClicked: {
                settingsPopup.open()
            }
        }

        Text{
            Layout.preferredWidth: 30
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignHCenter
            font.family: IcoMoon.iconmoon
            text: IcoMoon.raccoon
            font.pixelSize: 24
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: Colors.raccoon_icon
            visible: Colors.isDarkTheme
        }

        Image {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/images/UI/Images/raccoonline.png"
            visible: !Colors.isDarkTheme
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

                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                    }

                    SquareButton {
                        Layout.fillHeight: true
                        Layout.preferredWidth: menuRl.height
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.storage
                        selected: root.sellected_window === MenuSelector.Dfs
                        onClicked: root.sellected_window = MenuSelector.Dfs
                        text: "Storage"
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
                        icon: IcoMoon.wallet
                        selected: root.sellected_window === MenuSelector.Wallet || onboarding_current_page === Onboarding.Wallet_Access
                        onClicked: root.sellected_window = MenuSelector.Wallet
                        text: "Wallet"
                        style: Colors.button_menu_square_default_style
                        menu_button: true
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 0 // 15
                visible: false // ios_platform
            }
        }
    }

    states: [
        State {
            name: "if_not_mobile"
            when: !root.isMobile
            // PropertyChanges { target: menuCl; visible: true }
            // PropertyChanges { target: menuRl; visible: false }
            // PropertyChanges { target: menuClOld; visible: true }
            // PropertyChanges { target: menuRlOld; visible: false }
            PropertyChanges { target: menu; Layout.fillHeight: true; Layout.preferredWidth: 64 }
        },
        State {
            name: "if_mobile"
            when: root.isMobile
            // PropertyChanges { target: menuCl; visible: false }
            // PropertyChanges { target: menuRl; visible: true }
            // PropertyChanges { target: menuClOld; visible: false }
            // PropertyChanges { target: menuRlOld; visible: true }
            PropertyChanges { target: menu; Layout.fillWidth: true; Layout.preferredHeight: 64 }
        }
    ]
}
