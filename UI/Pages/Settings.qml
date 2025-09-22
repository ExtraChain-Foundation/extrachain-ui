import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import ExtraChain 1.0

import "../Fonts"
import "../Controls"
import "../"

Item {
    id: settingsPage
    visible: root.sellected_window === MenuSelector.Settings && isMobile
    anchors.fill: parent

    readonly property double minDiskSpaceForFullModeRequired: 2.0
    property string availableGB: raccoonController.availableGB
    property bool is_new_version: false
    property bool cheatMode
    property bool canUpdate

    Component.onCompleted: {
        checkAvailableFullMode()
    }

    function checkAvailableFullMode() {
        raccoonController.availableFullModeInit()
        availableGB = raccoonController.availableGB
        if((raccoonController.availableGB < minDiskSpaceForFullModeRequired) && !warningMessageBox.visible && appSettings.showMessageSwitchToLightMode) {
            console.log("In full mode")
            console.log("need show mesage about ff")
            warningMessageBox.title = "  RaccoonLine"
            warningMessageBox.info_text = "You have less than 2 GB of free memory remaining.<br>To receive full rewards, more memory is required.<br>Otherwise, the app will switch to Light Chain Mode."
            warningMessageBox.use_check_box = true
            warningMessageBox.check_box_text = "Do not display this message again"
            warningMessageBox.nameCallFunction = "TimerCheckMemory"
            warningMessageBox.visible = true
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: isMobile
        color:  Colors.settings_page.background
    }

    Timer {
        id: memoryCheckerTimer
        interval: 5 * 1000 * 60 //5 MIN
        running: appSettings.showMessageSwitchToLightMode
        onTriggered: {
            let isLight = uiController?.isBlockchainLight()
            if(!isLight) {
                console.log("run function checkAvailableFullMode().")
                checkAvailableFullMode()
            } else {
                console.log("timer repeat")
                memoryCheckerTimer.restart()
            }
        }
    }

    Connections {
        target: warningMessageBox

        function onClosed() {
            console.log("memory checker close", warningMessageBox.confirmed)
            if(warningMessageBox.confirmed) {
                appSettings.showMessageSwitchToLightMode = false
                console.log("disable show message box.")
            }
            memoryCheckerTimer.stop()
        }
    }

    RowLayout {
        id: rwMobileTitle
        anchors.topMargin: 1
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
                anchors.left: parent.left
                anchors.right: parent.horizontalCenter
                height: parent.height

                Rectangle {
                    height: parent.height
                    width: height
                    radius: height/2
                    color: Colors.mobile_notification_settings_box

                    IconText {
                        anchors.centerIn: parent
                        text: IcoMoon.bell
                        color: Colors.mobile_notification_settings_text
                        font.pixelSize: 22
                        opacity: parent.pressed ? 0.8 : 1.0
                    }
                }



                onClicked: {
                    console.log("show notifications")
                    root.sellected_window = MenuSelector.Notification
                }
            }

            MouseArea {
                id: maSettings
                anchors.left: parent.horizontalCenter
                anchors.right: parent.right
                height: parent.height
                property int saved_previous_window

                Rectangle {
                    height: parent.height
                    width: height
                    radius: height/2
                    color: Colors.mobile_notification_settings_box
                    border.width: 1
                    border.color: Colors.settings_page.border_color

                    IconText {
                        anchors.centerIn: parent
                        text: IcoMoon.settings
                        color: Colors.settings_page.icon
                        font.pixelSize: 22
                        opacity: parent.pressed ? 0.8 : 1.0
                    }
                }

                Connections {
                    target: root
                    onSellected_windowChanged: {
                        if(root.sellected_window !== MenuSelector.Settings)
                            maSettings.saved_previous_window = root.sellected_window
                    }
                }

                onClicked: {
                    console.log("show settings", root.sellected_window, settingsPopup.visible)
                    if(root.sellected_window === MenuSelector.Settings) {
                        if(saved_previous_window === MenuSelector.Vpn)
                            root.sellected_window = MenuSelector.Vpn
                        else if(saved_previous_window === MenuSelector.Wallet)
                            root.sellected_window = MenuSelector.Wallet
                        else if(saved_previous_window === MenuSelector.Locations)
                            root.sellected_window = MenuSelector.Locations
                        else
                            root.sellected_window = MenuSelector.Vpn
                    }
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
        clip: true
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
                    settingsPopup.close()
                }
            }

            RowLayout {
                Layout.alignment: isMobile ? Qt.AlignLeft : Qt.AlignHCenter
                Layout.fillWidth: true
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
                            settingsPopup.close()
                            root.sellected_window = MenuSelector.Vpn
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
                    text: "Settings"
                    color:  Colors.def_color_text
                    font.pixelSize: isMobile ? 24 : 18
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScrollView {
                    width: parent.width
                    height: parent.height - 20
                    y: root.isMobile ? 0 : 20
                    ScrollBar.horizontal.interactive: true
                    ScrollBar.vertical.interactive: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    contentHeight: cl.implicitHeight
                    contentWidth: dfsRoot.width


                    ColumnLayout {
                        id: cl
                        anchors.fill: parent
                        spacing: 20

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Export profile"
                            icon: IcoMoon.export_profile
                            onClicked: {
                                stackview.push(exportProfileComponent)
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Account"
                            icon: IcoMoon.user
                            onClicked: {
                                stackview.push(accountComponent)
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Subscription"
                            icon: IcoMoon.subscribe
                            visible: false
                            onClicked: {
                                settingsPopup.visible = false
                                root.sellected_window = MenuSelector.Wallet
                                walletPage.showSubscriptionPage()
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Light Chain"
                            icon: IcoMoon.light_chain
                            onClicked: {
                                raccoonController.availableFullModeInit()
                                stackview.push(lightChainComponent)
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Face ID"
                            icon: IcoMoon.face_id
                            visible: ios_platform && faceIdAvailable
                            onClicked: {
                                stackview.push(iosFaceIdAuthenticateComponent)
                            }
                        }

                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Software Rendering"
                            icon: IcoMoon.rendering
                            checked: appSettings.softwareRendering

                            onClicked: {
                                console.log("Software rendering changed", checked)
                                notificationToolTip.showMessage("Changes will take effect after restart")
                                appSettings.softwareRendering = checked
                            }
                        }

                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Hide mining reward"
                            icon: IcoMoon.rendering
                            visible: UiSettings.debugMode
                            checked: appSettings.hideMining
                            onClicked: {
                                console.log("Hide mining reward changed", checked)
                                walletUIController?.showWalletTransactions("", checked)
                                notificationController.showMiningRewardNotifications(checked)
                                appSettings.hideMining = checked
                            }
                        }

                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            checked: appSettings.isDarkTheme
                            text: appSettings.isDarkTheme ? "Dark theme" : "Light theme"
                            icon: appSettings.isDarkTheme ? IcoMoon.dark_theme : IcoMoon.light_theme

                            onClicked: {
                                console.log("Theme changed", checked)
                                appSettings.isDarkTheme = checked
                                Colors.isDarkTheme = appSettings.isDarkTheme
                            }
                        }

                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            checked: root.cheatMode
                            text: root.cheatMode ? "Return to mortality" : "Almighty"
                            icon: root.cheatMode ? IcoMoon.happy : IcoMoon.circle
                            visible: UiSettings.debugMode

                            onClicked: {
                                console.log("Almighty changed", checked)
                                root.cheatMode = checked
                                var message = root.cheatMode ? "⚡ GODMODE ACTIVATED ⚡\nWith great power..." : "Back to suffering, mortal"
                                notificationToolTip.showMessage(message)
                            }
                        }

                        /*
                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            // checked: root.cheatMode
                            text: checked ? "Enable export keystore next time" : "Disable export keystore next time"
                            icon: IcoMoon.import_keystore
                            visible: UiSettings.debugMode

                            onClicked: {
                                checked = checked
                                console.log("Changed ", text)
                                // appSettings.showExportPage = checked
                            }
                        }
                        */

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Connections"
                            icon: IcoMoon.connections
                            visible: UiSettings.debugMode
                            onClicked: {
                                stackview.push(connectionsComponent)
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "License Details"
                            icon: IcoMoon.license
                            visible: UiSettings.debugMode
                            onClicked: {
                                notificationToolTip.showMessage("Soon. Available later.")
                            }
                        }

                        SwitchSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: checked ? "Enable UPnP" : "Disable UPnP"
                            icon: checked ? IcoMoon.happy : IcoMoon.circle
                            visible: UiSettings.debugMode

                            onClicked: {
                                console.log("UPnP changed", checked)
                                // checked = isCheck
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Show tutorial"
                            icon: IcoMoon.attention
                            onClicked: {
                                appSettings.onboard_finished = false
                                onboarding_current_page = Onboarding.Vpn_Tab_To_Connect
                                root.sellected_window = MenuSelector.Vpn
                                settingsPopup.close()
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Check Update"
                            icon: IcoMoon.update
                            visible: UiSettings.debugMode
                            onClicked: {
                                enabled = false
                                settingsPage.canUpdate = uiController.checkUpdate()
                                enabled = true

                                if (settingsPage.canUpdate) {
                                    notificationToolTip.showMessage("New software updates are available")
                                    updater.visible = true
                                } else {
                                    notificationToolTip.showMessage("Your software is up to date")
                                }
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Remove profiles and all user data"
                            icon: IcoMoon.trash
                            visible: UiSettings.debugMode
                            _colorIcon: Colors.red
                            _textColor: Colors.red
                            onClicked: {
                                forceClose = true
                                uiController.logOut()
                                uiController.setNeedWipe(true)
                                Qt.quit()
                            }
                        }

                        ActionSettingsItem {
                            Layout.preferredHeight: 64
                            Layout.fillWidth: true
                            text: "Logout"
                            icon: IcoMoon.logout
                            _colorIcon: Colors.red
                            _textColor: Colors.red
                            onClicked: {
                                forceClose = true
                                const keychainName = "Hash" + (etUtils.isRelease ? "" : "Debug")
                                keyChain.deleteKey(keychainName)
                                uiController.logOut()
                                Qt.quit()
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            Layout.topMargin: -10
                            Layout.bottomMargin: -5

                            DevActivator {
                                anchors.fill: parent
                            }

                            DmsansText {
                                anchors.centerIn: parent
                                text: versionStr
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: Colors.settings_page.text
                                font.pixelSize: _font_pixel_size - 2
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: accountComponent

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
                    text: "Account"
                    font.pixelSize: 24
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                    font.weight: 600
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
            }

            RaccoonTextField {
                id: usernameTf
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                text: uiController.loadUserName(raccoonController?.mainActor)
                font.pixelSize: 16
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
            }

            BlueButton {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter
                text: "Save"
                filled: true
                property string new_user_name: usernameTf.text
                enabled: uiController.loadUserName(raccoonController?.mainActor) !== new_user_name && new_user_name.length > 5
                onClicked: {
                    var message = ""
                    if (new_user_name.length === 0) {
                        const res = uiController.removeUsername()
                        message = res ? "Username successfully removed" : "Error"
                        notificationToolTip.showMessage(message)
                        return
                    }

                    if (new_user_name.length > 30) {
                        message = "Username must be lower than 30"
                        notificationToolTip.showMessage(message)
                        return
                    }

                    if (uiController.existsUsername(new_user_name)) {
                        message = "Username already exists"
                        notificationToolTip.showMessage(message)
                        return
                    }

                    const res = uiController.addUsername(new_user_name)

                    message = res ? "Username saved successfully" : "Error"
                    notificationToolTip.showMessage(message)
                    if(res)
                        stackview.pop()
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }


            RaccoonIconTextButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 22
                spacing: 6
                icon: IcoMoon.logout
                text: "Logout"
                onClicked: {
                    uiController.logOut()
                    uiController.setNeedWipe(true)
                    Qt.quit()
                }
            }
        }
    }

    Component {
        id: exportProfileComponent

        Item {
            enabled: !exportDialog.visible && !exportMobileDialog.visible

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 64 : 0
                Layout.maximumHeight: 64

                SquareButton {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 32
                    Layout.alignment: Qt.AlignVCenter
                    icon: IcoMoon.down
                    rotation: 90
                    menu_button: true
                    onClicked: {
                        stackview.pop()
                    }
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    text: "Export profile"
                    font.pixelSize: 24
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                id: typeRecoveryList
                height: contentHeight
                width: 170
                anchors.centerIn: parent
                clip: true
                interactive: false
                model: isNewProfile ? ["Export as File", "Export as Phrase", "Export as Hex"] : ["Export as File"]

                delegate: RaccoonButton {
                    height: 60
                    width: 170
                    text: modelData

                    onClicked: {
                        console.log("Pressed index:", index)
                        exportDialog.is_new_version = (index === 1 || index === 2)
                        exportDialog.type = index
                        if(isMobile)
                            exportMobileDialog.visible = true
                        else
                            exportDialog.visible = true
                    }
                }
            }

        }
    }

    Component {
        id: lightChainComponent
        ColumnLayout {
            anchors.fill: parent

            onVisibleChanged: {
                raccoonController.availableFullModeInit()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 64 : 0
                Layout.maximumHeight: 64

                SquareButton {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: 32
                    Layout.alignment: Qt.AlignVCenter
                    icon: IcoMoon.down
                    rotation: 90
                    menu_button: true
                    onClicked: {
                        stackview.pop()
                    }
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    text: "Light Chain"
                    font.pixelSize: 24
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 50

                DmsansText {
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 200
                    text: "Available storage"
                    color: Colors.green
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                }

                DmsansText {
                    Layout.preferredHeight: 50
                    Layout.preferredWidth:  100
                    text: availableGB + " GB"
                    color: Colors.green
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 50

                DmsansText {
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 200
                    text: "Light Chain"
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                }

                Item {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth:  50
                    Layout.alignment: Qt.AlignVCenter

                    RaccoonSwitch {
                        id: cmbxLightSwitchControl
                        anchors.centerIn: parent
                    }
                }
            }

            BlueButton {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter
                text: "Save"
                filled: true
                property bool originalIsLight: false

                Component.onCompleted: {
                    cmbxLightSwitchControl.checked = uiController?.isBlockchainLight() || false

                    if(raccoonController.availableGB < raccoonController.fullDagModeMinSize && !cmbxLightSwitchControl.checked) {
                        cmbxLightSwitchControl.checked = true
                    }
                    originalIsLight = cmbxLightSwitchControl.checked
                }

                enabled: cmbxLightSwitchControl.checked !== originalIsLight
                onClicked: {
                    console.log("Settings. Save blue button. Params: ", raccoonController.availableGB, raccoonController.fullModeMinGb, !cmbxLightSwitchControl.checked)
                    if(raccoonController.availableGB < raccoonController.fullDagModeMinSize && !cmbxLightSwitchControl.checked) {
                        cmbxLightSwitchControl.checked = true
                        console.log("Settings. Save blue button Not enough storage available.<br>Only Light Mode can be enabled")
                        notificationToolTip.showMessage("Not enough storage available.<br>Only Light Mode can be enabled.")
                        return;
                    }

                    uiController.setBlockchainLight(cmbxLightSwitchControl.checked)
                    const isOriginal = originalIsLight === cmbxLightSwitchControl.checked
                    originalIsLight = cmbxLightSwitchControl.checked
                    notificationToolTip.message = isOriginal ?
                                "Changes have been reverted" :
                                "Changes will take effect after restart"
                    notificationToolTip.showMessage()
                    stackview.pop()
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: connectionsComponent

        Item {
            function updateConnectionsList() {
                connectionsList.model = uiController?.networkConnections() || []
            }

            Component.onCompleted: {
                updateConnectionsList()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 20
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 15
                    Layout.rightMargin: 15

                    SquareButton {
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: 32
                        Layout.alignment: Qt.AlignVCenter
                        icon: IcoMoon.down
                        rotation: 90
                        menu_button: true
                        onClicked: {
                            stackview.pop()
                        }
                    }

                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: "Connections: " + (uiController?.networkStatus ? uiController?.networkSockets : "no")
                        color: Colors.def_color_text
                        font.pixelSize: 16
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.leftMargin: 15
                    Layout.rightMargin: 15

                    RaccoonCheckBox {
                        id: autoupdateCB
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 140
                        height: 24
                        width: 140
                        Layout.alignment: Qt.AlignVCenter
                        text: "Autoupdate"
                        unchecked: Colors.wallet_withdraw_page.uncheckBackground
                        checked: UiSettings.debugMode
                        visible: UiSettings.debugMode

                        Timer {
                            repeat: true
                            interval: 5000
                            running: parent.checked
                            onTriggered: updateConnectionsList()
                        }
                    }

                    Item {
                        Layout.preferredHeight: parent.height
                        Layout.fillWidth: true
                    }

                    BlueButton {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 180
                        Layout.alignment: Qt.AlignVCenter
                        filled: true
                        text: "Update connections"
                        visible: UiSettings.debugMode
                        onClicked: updateConnectionsList()
                    }
                }

                // Connections list
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    ListView {
                        id: connectionsList
                        anchors.fill: parent
                        anchors.topMargin: 5
                        clip: true

                        Component.onCompleted: {
                            connectionsList.model = uiController?.networkConnections() || []
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: connectionsList.contentHeight > connectionsList.height ?
                                        ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                        }

                        delegate: Rectangle {
                            width: connectionsList.width
                            height: 40
                            color: "transparent"

                            property string protocol: modelData && modelData.protocol === 'UDP' ? 'udp' : 'ws'

                            DmsansText {
                                anchors.fill: parent
                                leftPadding: 14
                                text: modelData ?
                                          (modelData.ip + ' | ' + (modelData.identifier.slice(0, 4) + '..' + modelData.identifier.slice(-4))
                                           + '<br>i: '  + settingsPage.formatBytes(modelData.incoming) + ' o: ' + settingsPage.formatBytes(modelData.outgoing))
                                        : "No connection data"
                                color: Colors.settings_page.text || "white"
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12
                                height: width
                                radius: width / 2
                                color: modelData && modelData.active ? 'green' : 'red'
                                visible: modelData !== undefined
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (!modelData || modelData.identifier === '0' || modelData.identifier === '')
                                        return
                                    enabled = false
                                    uiController.networkConnectionRemove(modelData.identifier)
                                    enabled = true
                                    updateConnectionsList()
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "No connections available"
                            color: "white"
                            font.pixelSize: 16
                            visible: connectionsList.count === 0
                        }
                    }
                }
            }
        }
    }

    Component {
        id: iosFaceIdAuthenticateComponent
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
                    icon: IcoMoon.down
                    rotation: 90
                    menu_button: true
                    onClicked: {
                        stackview.pop()
                    }
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    text: "Face ID"
                    font.pixelSize: 24
                    color: Colors.def_color_text
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 50

                DmsansText {
                    Layout.preferredHeight: 50
                    Layout.fillWidth: true
                    text: "Use Face ID for login"
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                }

                RaccoonSwitch {
                    id: loginFaceIDSwitch
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignVCenter
                    checked: appSettings.iosFaceIdLogin
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 50

                DmsansText {
                    Layout.preferredHeight: 50
                    Layout.fillWidth: true
                    text: "Require Face ID for payments"
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                }

                RaccoonSwitch {
                    id: paymentFaceIDSwitch
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignVCenter
                    checked: appSettings.iosFaceIdPayment
                }
            }

            BlueButton {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 48
                Layout.alignment: Qt.AlignHCenter
                text: "Save"
                filled: true
                property bool originalIsLight: false
                onClicked: {
                    appSettings.iosFaceIdLogin = loginFaceIDSwitch.checked
                    appSettings.iosFaceIdPayment = paymentFaceIDSwitch.checked
                    console.log("Save Login Face id", appSettings.iosFaceIdLogin)
                    console.log("Save payment Face id", appSettings.iosFaceIdPayment)
                    stackview.pop()
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

    component ActionSettingsItem: Item {
        id: actionSettingsItem
        property alias mouseSettingsItem: inner_mouseSettingsItem
        Layout.preferredHeight: 64
        Layout.fillWidth: true
        property alias _colorIcon: icon.color
        property alias _textColor: textSettingsParameter.color

        property string icon
        property string text
        signal clicked()

        ColumnLayout {
            width: parent.width
            height: isMobile ? 72 : 68

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: isMobile ? 72 : 68
                spacing: 6

                IconText {
                    id: icon
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: 16
                    font.pixelSize: 16
                    text: actionSettingsItem.icon
                    color: Colors.grape_gray_color
                    opacity: actionSettingsItem.mouseSettingsItem.pressed ? 0.7 : 1.0
                }

                DmsansText {
                    id: textSettingsParameter
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 32
                    Layout.fillWidth: true
                    text: actionSettingsItem.text
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    verticalAlignment: Text.AlignVCenter
                    opacity: actionSettingsItem.mouseSettingsItem.pressed ? 0.7 : 1.0
                }

                IconText {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    font.pixelSize: 24
                    text: IcoMoon.down
                    rotation: 270
                    color: Colors.def_color_text
                    opacity: actionSettingsItem.mouseSettingsItem.pressed ? 0.7 : 1.0
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        MouseArea {
            id: inner_mouseSettingsItem
            anchors.fill: parent
            onClicked: {
                parent.clicked()
            }
        }
    }

    component SwitchSettingsItem: Item {
        id: switchSettingsItem
        Layout.preferredHeight: 64
        Layout.fillWidth: true
        property string icon
        property string text
        property bool checked
        signal clicked

        RowLayout {
            width: parent.width
            height: isMobile ? 72 : 68

            spacing: 6

            IconText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
                font.pixelSize: 16
                text: switchSettingsItem.icon
                color: Colors.grape_gray_color
                opacity: switchSettingsMouse.pressed ? 0.7 : 1.0
            }

            DmsansText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 32
                Layout.fillWidth: true
                text: switchSettingsItem.text
                color: Colors.def_color_text
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                opacity: switchSettingsMouse.pressed ? 0.7 : 1.0
            }

            RaccoonSwitch {
                id: cmbxLightSwitchControl
                Layout.preferredWidth: 48
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                checked: switchSettingsItem.checked
            }
        }

        MouseArea {
            id: switchSettingsMouse
            anchors.fill: parent
            onClicked: {
                // cmbxLightSwitchControl.checked = !cmbxLightSwitchControl.checked
                switchSettingsItem.checked = !switchSettingsItem.checked
                switchSettingsItem.clicked()
            }
        }
    }

    function formatBytes(bytes, decimals = 2) {
        let negative = bytes < 0
        if (negative) bytes = Math.abs(bytes)
        if (bytes === 0) return '0 bytes'

        const k = 1024
        const dm = decimals < 0 ? 0 : decimals
        const sizes = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
        const i = Math.floor(Math.log(bytes) / Math.log(k))

        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm) * (negative ? -1 : 1)) + ' ' + sizes[i]
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
}
