import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore as QtCore
import ExtraChain 1.0
import QtQuick.Effects


import "UI/Controls"
import "UI/Pages"
import "UI/Pages/Wallet"
import "UI/Fonts"
import "UI"

ApplicationWindow {
    id: root
    width: 900
    height: 700
    minimumHeight: 540
    minimumWidth: 400
    visible: true
    title: Qt.platform.os !== "osx" ? "ExtraChain " + (isMessenger ? "Messenger" : "Wallet") : ""
    color: Colors.background
    Material.accent: Material.Blue
    flags: Qt.platform.os === "windows" ? Qt.Window :
                                          Qt.platform.os === "osx" || android_platform ? (Qt.ExpandedClientAreaHint | Qt.NoTitleBarBackgroundHint) :
                                                                                         (Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint)

    Material.theme: appSettings.isDarkTheme ? Material.Dark : Material.Light
    onHeightChanged: console.log("h:", height)

    property int sellected_window: isMessenger ? MenuSelector.Messenger : MenuSelector.Dfs
    property int onboarding_current_page: Onboarding.Wallet_Access
    onSellected_windowChanged: {
        if(loader_Item.item.subscription_page.visible) {
            loader_Item.item.subscription_page.visible = false
        }
    }    

    property alias appSettings: appSettings
    property bool isMobile: ios_platform || (android_platform && !isTablet) || root.width < 450
    property bool isDesktop: ["windows", "linux", "osx", "macos"].includes(Qt.platform.os)
    property bool ios_platform: Qt.platform.os === "ios"
    property bool android_platform: Qt.platform.os === "android"
    property int keyboardHeight: ios_platform  ? 0 : Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio
    property int statusHeight
    property int navigationHeight
    property string versionStr: "version " + raccoonVersion + " " + arch + (android_platform ? ", " + (isPlayMarket ? "store" : "direct" ) : "")
    property string general_font: Montserrat.dmsans
    property real safeAreaMarginTop: isMobile ? 0 : root.SafeArea.margins.top
    property bool vpn_client_mode: appSettings.vpnModeIndex === 0
    property bool isNewProfile
    readonly property bool isOnboardingState: !appSettings.onboard_finished
    property bool logined
    property bool cheatMode
    property bool securityState
    property bool faceIdAvailable: raccoonController.isFaceIDAvailable()
    property bool accepted: Qt.platform.os !== "android"


    Component.onCompleted: {
        statusHeight = statusBarHelper.getStatusBarHeight()
        navigationHeight = statusBarHelper.getNavigationBarHeight()
        root.requestActivate()
        root.raise()
    }

    onIsMobileChanged: {
        if (!isMobile && editWalletPopup.visible) {
            editWalletPopup.visible = false
        }

        if (isMobile && settingsPopup.visible) {
            settingsPopup.close()
        }

        if (isMobile && notificationPopup.visible) {
            notificationPopup.close()
        }

        if (!isMobile && sellected_window === MenuSelector.Notification) {
            notificationPopup.visible = true
        }

        if (!isMobile && sellected_window === MenuSelector.Settings) {
            settingsPopup.visible = true
        }
    }

    property bool forceClose
    onClosing: function(close) {
        // if (isMobile && sellected_window === MenuSelector.Messenger && messengerPage.swipeView.currentIndex !== 0) {
        //     messengerPage.swipeView.currentIndex = 0
        //     close.accepted = false
        //     return
        // }

        if (!android_platform) {
            return
        }

        close.accepted = forceClose

        if (!close.accepted) {
            messageBox.open()
        }
    }

    MouseArea {
        z: 1
        width: root.width
        height: Math.max(root.SafeArea.margins.top, 20)
        y: -root.SafeArea.margins.top
        visible: Qt.platform.os === "osx"

        onPressed: {
            root.startSystemMove()
        }
        onDoubleClicked: {
            if (root.visibility === Window.Maximized) {
                root.showNormal()
            } else {
                root.showMaximized()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: isDesktop
        onPressed: root.startSystemMove()
    }

    Component {
        id: generalPagesComponent

        GeneralPages {}
    }

    Loader {
        id: loader_Item
        sourceComponent: generalPagesComponent
        anchors.fill: parent
        active: !loginPage.visible && !updater.visible
        onLoaded: item.forceActiveFocus()
    }

    RaccoonOkMessageBox {
        id: warningMessageBox
        use_check_box: false
        property string nameCallFunction

        onAgree: {
            close()
        }
    }

    Loader {
        id: loaderWithdrawal
        anchors.fill: parent
        anchors.leftMargin: isMobile ? 0 : loader_Item.item.menu_selector.width+36
        anchors.rightMargin: isMobile ? 0 : 16
        anchors.topMargin: isMobile ? 0 : 16
        anchors.bottomMargin: isMobile ? 0 : 16
        visible: false
    }

    LoginPage {
        id: loginPage
        anchors.bottomMargin: keyboardHeight
    }

    RaccoonMessageBox {
        id: messageDialog
        onAccepted: {
            console.log("pressed OK wipe data.")
            Qt.openUrlExternally("https://raccoonline.com/#download")
            // raccoonController.clearData();
            root.close()
        }
        onRejected: {
            console.log("pressed cancel. close app.")
            root.close()
        }
    }

    Connections {
        target: raccoonController

        function onWipeData(ty, title, question) {
            if (Qt.platform.os === "ios") {
                return
            }

            if (ty === 2 || ty === 3) {
                updater.visible = true
                return
            }

            messageDialog.title = title
            messageDialog.info_text = question
            messageDialog.use_check_box = false
            messageDialog.open()
        }
    }

    QtCore.Settings {
        id: appSettings
        property bool isDarkTheme: true
        property bool hideMining: false
        property bool softwareRendering: false
        property bool newVersion: true
        property bool showExportPage: false
        property int depositSelectedWalletIndex: -1
        property double trialStartTimestamp
        property int vpnModeIndex: 0
        property int onboard_current_index_page
        property bool onboard_finished: false
        property bool showMessageSwitchToLightMode: true

        property bool iosFaceIdLogin: false
        property bool iosFaceIdPayment: false
        property string selectedWallet: ""
        property int showWalletState: 0

        Component.onCompleted: {
            if (trialStartTimestamp === 0) {
                trialStartTimestamp = Date.now()
            }

            // console.log("[Trial]", trialStartTimestamp)
            trialStartDate = new Date(appSettings.trialStartTimestamp)

            // trialStartDate = new Date(Date.now() - (7 * 24 * 60 * 60 * 1000) + (60 * 1000 * 3.1))
            Colors.isDarkTheme = appSettings.isDarkTheme
            appSettings.showExportPage = false
            onboard_finished = true
        }
    }

    QtCore.Settings {
        id: settingsWindow
        category: "ApplicationWindow"
        property alias x: root.x
        property alias y: root.y
        property alias width: root.width
        property alias height: root.height
        property alias visibility: root.visibility
        property int sellectedWindow: root.sellected_window

        Component.onCompleted: {
            root.sellected_window = sellectedWindow
        }
    }

    Updater {
        id: updater
    }

    RaccoonMessageBox {
        id: messageBox
        title: "ExtraChain"
        info_text: "Are you sure you want to exit?"
        use_check_box: false

        onAgree: {
            root.accepted = true
            // root.close()
            raccoonController.closeApp()
        }
    }


    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive) {
                root.update()
                root.requestActivate()
                root.raise()
            }
        }
    }

    RaccoonOkMessageBox {
        id: messageFromVpnBox
        title: "ExtraChain"
        info_text: "Access to the required permissions was not granted.<br>
                    The application cannot continue and will be closed."
        use_check_box: false

        onAgree: {
            Qt.quit()
        }
    }

    NotificationToolTip {
        id: notificationToolTip
    }

    // Trial: start
    Timer {
        running: !uiController.subscribed && appSettings.trialStartDate !== 0
        repeat: true
        triggeredOnStart: true
        interval: trialTimeRemainingMs > 3610000 ? 30 * 1000 : 1000

        onTriggered: {
            var totalMs = 7 * 24 * 60 * 60 * 1000 - (Date.now() - trialStartDate.getTime())
            if (totalMs <= 0) {
                stop()
                return
            }

            isTrialActive = totalMs > 0
            trialTimeRemainingMs = totalMs >= 0 ? totalMs : 0
            // console.log("[Trial] isTrialActive:", isTrialActive, '| remaining ms:', totalMs)
        }
    }

    property date trialStartDate
    property bool isTrialActive
    property int trialTimeRemainingMs
    property string trialTimeRemaining: {
        if (trialTimeRemainingMs <= 0) return "0 seconds"
        var days = Math.floor(trialTimeRemainingMs / (24 * 60 * 60 * 1000))
        var hours = Math.floor((trialTimeRemainingMs % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000))
        var minutes = Math.floor((trialTimeRemainingMs % (60 * 60 * 1000)) / (60 * 1000))
        var seconds = Math.floor((trialTimeRemainingMs % (60 * 1000)) / 1000)

        if (days > 0) {
            var daysText = days + (days === 1 ? " day" : " days")
            if (hours > 0) {
                daysText += " " + hours + (hours === 1 ? " hour" : " hours")
            }
            return daysText
        } else if (hours > 0) {
            var hoursText = hours + (hours === 1 ? " hour" : " hours")
            if (minutes > 0) {
                hoursText += " " + minutes + (minutes === 1 ? " minute" : " minutes")
            }
            return hoursText
        } else if (minutes > 0) {
            var minutesText = minutes + (minutes === 1 ? " minute" : " minutes")
            if (seconds > 0 && minutes < 3) {
                minutesText += " " + seconds + (seconds === 1 ? " second" : " seconds")
            }
            return minutesText
        } else {
            return seconds + (seconds === 1 ? " second" : " seconds")
        }
    }
    // Trial: end

    function reverseDevMode() {
        UiSettings.debugMode = !UiSettings.debugMode
    }

    function showExportPage() {
        exportPage.visible = true
    }


    // hack for Qt 6.9.2: start
    Item {
        id: appWindowInvalidateItem
    }

    Timer {
        id: appWindowInvalidateTimer
        interval: 50
        onTriggered: {
            ++appWindowInvalidateItem.width
            --appWindowInvalidateItem.width
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                appWindowInvalidateTimer.restart()
            }
        }
    }
    // hack for Qt 6.9.2: end
}
