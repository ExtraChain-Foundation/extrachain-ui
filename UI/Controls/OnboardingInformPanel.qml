import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

Rectangle {
    id: onbordindControl
    width: 340
    height: clOnboarding.implicitHeight + 32
    color: Colors.background
    radius: 8
    anchors.fill: parent
    border.color: Colors.onboarding.border

    readonly property int _implicitHeightInfo: clOnboarding.implicitHeight
    property int index_page: (onboarding_current_page >= Onboarding.Wallet_Estimate_Balance
                               ? onboarding_current_page - Onboarding.Storage_Notification_and_Settings : onboarding_current_page >= Onboarding.Storage_Space
                              ? onboarding_current_page - Onboarding.Notifications_And_Settings
                              : onboarding_current_page + 1)

    property int count_steps: onboarding_current_page >= Onboarding.Wallet_Estimate_Balance ? 3 : onboarding_current_page >= Onboarding.Storage_Space ? 5 : 6

    SquareButton{
        anchors.right: parent.right
        width: 30
        height: 30
        icon: IcoMoon.close
        pressed_color: Colors.onboarding.close_button_pressed_color
        koef_icon_size: 1.0
        onClicked: {
            console.log("on_clicked")
            onboarding_current_page = Onboarding.Finished
            appSettings.onboard_finished = true
        }
    }
    
    ColumnLayout {
        id: clOnboarding
        anchors.centerIn: parent
        width: 312
        anchors.horizontalCenter: parent.horizontalCenter
        
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            DmsansText {
                id: titleText
                Layout.fillWidth: true
                Layout.preferredHeight: paintedHeight
                text: title()
                color: Colors.onboarding.title
                font.weight: 600
                font.pixelSize: 16
            }
        }
        
        DmsansText {
            id: descriptionText
            Layout.fillWidth: true
            Layout.preferredHeight: text.length > 0 ? paintedHeight : 0
            color: Colors.onboarding.description
            text: description()
            font.weight: 400
            font.pixelSize: 14
            visible: text.length > 0
        }
        
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
        }

        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Colors.grape_gray_color
        }
        
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            
            DmsansText {
                id: stepText
                anchors.bottom: parent.bottom
                width: paintedWidth
                height: 40
                color: Colors.onboarding.step_text
                text: qsTr("Step ") + onbordindControl.index_page +qsTr(" of ") + onbordindControl.count_steps
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
                font.weight: 500
            }
            
            BlueButton {
                anchors.verticalCenter: stepText.verticalCenter
                anchors.right: parent.right
                width: 107
                height: 40
                filled: true
                text: onboarding_current_page !== Onboarding.Wallet_Select ? qsTr("Next") : qsTr("Complete")
                _label.font.weight: 500
                onClicked: {
                    if(onboarding_current_page === Onboarding.Storage_Space -1) {
                        currentPage = MenuSelector.Dfs
                    }

                    if(onboarding_current_page === Onboarding.Wallet_Estimate_Balance -1) {
                        currentPage = MenuSelector.Wallet
                    }

                    if(text === qsTr("Complete")) {
                        onboarding_current_page = Onboarding.Finished
                        appSettings.onboard_finished = true
                        currentPage = MenuSelector.Vpn
                        appSettings.onboard_current_index_page = onboarding_current_page
                    } else {
                        onboarding_current_page++;
                        appSettings.onboard_current_index_page = onboarding_current_page
                    }
                }
            }
        }
    }

    function title() {
        switch(onboarding_current_page) {
        case Onboarding.Vpn_Tab_To_Connect: return qsTr("Tap to connect<br>securely to the VPN")
        case Onboarding.Vpn_Connection_Status: return qsTr("Connection Status")
        case Onboarding.Vpn_Location_Select: return qsTr("Location Select<br>& Connection Info")
        case Onboarding.Mining_Info: return qsTr("Mining Info")
        case Onboarding.Wallet_Access : return qsTr("Wallet Access")
        case Onboarding.Notifications_And_Settings: return qsTr("Notifications & Settings")
        case Onboarding.Storage_Space: return qsTr("Your remaining storage space<br>is shown here")
        case Onboarding.Storage_Upgrade: return qsTr("You can increase your<br>storage space here")
        case Onboarding.Storage_Search: return qsTr("Search for files by name")
        case Onboarding.Storage_View_Options: return qsTr("Tap and hold to view options")
        case Onboarding.Storage_Notification_and_Settings: return qsTr("Notifications & Settings")
        case Onboarding.Wallet_Estimate_Balance: return qsTr("Your estimated balance")
        case Onboarding.Wallet_Transaction_List: return qsTr("Your recent transactions<br>appear here")
        case Onboarding.Wallet_Select: return qsTr("Tap to create another wallet<br><br>")
        }
    }

    function description() {
        switch(onboarding_current_page) {
        case Onboarding.Vpn_Tab_To_Connect: return qsTr("Protect your data in one click")
        case Onboarding.Vpn_Connection_Status: return qsTr("Check if you’re securely connected or<br>not. Stay aware of your VPN protection")
        case Onboarding.Vpn_Location_Select: return qsTr("To proceed, please select a location from<br>the list of available options")
        case Onboarding.Mining_Info: return qsTr("Earn tokens while staying connected.<br>Passive rewards with every session")
        case Onboarding.Wallet_Access : return qsTr("Track your balance and earnings.<br>Everything you’ve mined in one place")
        case Onboarding.Notifications_And_Settings: return qsTr("Manage alerts and preferences here.<br>Set it once, enjoy forever.")
        case Onboarding.Storage_Space: return ""
        case Onboarding.Storage_Upgrade: return ""
        case Onboarding.Storage_Search: return ""
        case Onboarding.Storage_View_Options: return ""
        case Onboarding.Storage_Notification_and_Settings: return qsTr("Manage alerts and preferences here.<br>Set it once, enjoy forever.")
        case Onboarding.Wallet_Estimate_Balance: return qsTr("The value of crypto assets<br>changes dynamically")
        case Onboarding.Wallet_Transaction_List: return ""
        case Onboarding.Wallet_Select: return qsTr("SOL Balances, Change active<br>wallet")
        }
    }
}
