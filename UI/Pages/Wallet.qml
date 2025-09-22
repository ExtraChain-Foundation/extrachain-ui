import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "./Wallet"
import "../"

RaccoonPage {
    id: walletPage
    anchors.fill: parent
    anchors.topMargin: Qt.platform.os === "osx" ? -safeAreaMarginTop + 6 : 0
    visible: root.sellected_window === MenuSelector.Wallet && !subscription.visible
    property bool menuActive: false
    // property alias balanceButton: balanceButton
    readonly property int text_pixel_size: isMobile ? 12 : 14
    property bool selectWalletState: false
    property string selectedWallet: ""
    property string cachedWallet
    property bool editWalletState: false

    readonly property string estimateBalance: walletUIController?.estimatedBalance
    readonly property bool _is_syncing: estimateBalance === '~' || walletUIController?.syncing ? true : false
    readonly property string securityModeText: "Secure mode is active."

    readonly property var onboardingTransactionList: {
        let list = []
        for (let i = 0; i < 10; ++i) {
            let num = Math.random() * (300 - 30) + 30
            list.push(Number(num.toFixed(3)))
        }
        return list
    }

    onEditWalletStateChanged: {
        if(editWalletPopup.visible) {
            editWalletPopup.close()

        }
    }

    onVisibleChanged: {
        if(!visible) {
            editWalletState = false
            menuDesktopWallet.visible = false
            txDetailedPopup.visible = false
            popup.visible = false
            selectWalletState = false
            editWalletState = false
        }
    }

    onWidthChanged: {
        if(menuDesktopWallet.visible) {
            menuDesktopWallet.visible = false
            txDetailedPopup.visible = false
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: hideMenu.visible
        onClicked: {
            console.log("pressed")
            hideMenu.visible = false
        }

        onPressed: if (isDesktop) root.startSystemMove()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.leftMargin: isMobile ? 0 : 18
        anchors.rightMargin: isMobile ? 0 : 18
        visible: !selectWalletState // && !loaderWithdrawal.visible

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            visible: isMobile
            enabled: !isOnboardingState

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
                    anchors.left: parent.horizontalCenter
                    anchors.right: parent.right
                    height: parent.height

                    Rectangle {
                        height: parent.height
                        width: height
                        radius: height/2
                        color: Colors.mobile_notification_settings_box

                        IconText {
                            anchors.centerIn: parent
                            text: IcoMoon.settings
                            color: Colors.mobile_notification_settings_text
                            font.pixelSize: 22
                            opacity: parent.pressed ? 0.8 : 1.0
                        }
                    }

                    onClicked: {
                        console.log("show notifications")
                        root.sellected_window = MenuSelector.Settings
                    }
                }
            }
        }

        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.interactive: true
            ScrollBar.vertical.interactive: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            Connections {
                target: scrollView.contentItem
                onContentYChanged: {
                    topShadowRect.visible = (target && target.contentY > 160)
                }
            }

            ColumnLayout {
                width: parent.width
                height: implicitHeight

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: walletCl.implicitHeight + 50

                    MouseArea {
                        anchors.fill: walletCl
                        onPressed: if (isDesktop) root.startSystemMove()
                    }

                    RowLayout {
                        height: 22
                        width: parent.width - 10

                        Rectangle {
                            id: selectWalletRect

                            Layout.preferredHeight: 22
                            Layout.preferredWidth: 180
                            Layout.maximumWidth: Layout.preferredWidth
                            Layout.minimumWidth: rowlwallet.implicitWidth
                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignRight
                            color: Colors.wallet.select_wallet_background_button
                            radius: height / 2
                            opacity: isOnboardingState ? 0 : selectWallet.enabled ? 1.0 : 0.7
                            visible: !loaderWithdrawal.visible

                            RowLayout {
                                id: rowlwallet
                                width: 180
                                height: 22
                                DmsansText {
                                    id: selectedText
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 12
                                    leftPadding: 11
                                    elide: Text.ElideRight
                                    text: selectedWallet.length === 0 ? "Wallets" : Utils.mask(selectedWallet, securityState)
                                    color: Colors.wallet.select_wallet_button
                                    opacity: selectWallet.enabled ? 1.0 : 0.7
                                }
                                IconText {
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: Layout.preferredHeight
                                    text: IcoMoon.down
                                    rotation: 270
                                    color: Colors.def_color_text
                                    opacity: selectWallet.enabled ? 1.0 : 0.7
                                }
                            }

                            MouseArea {
                                id: selectWallet
                                anchors.fill: parent
                                anchors.margins: -30
                                enabled: !_is_syncing && !isOnboardingState

                                onClicked: {
                                    console.log("select wallet")
                                    selectWalletState = true
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: walletCl
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 20
                        height: implicitHeight
                        y: 40
                        spacing: 11

                        Item {
                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                            Layout.preferredHeight: isMobile ? 66 : 100
                            Layout.fillWidth: true

                            SwipeView {
                                id: view
                                anchors.fill: parent
                                clip: true
                                interactive: isMobile
                                currentIndex: appSettings.showWalletState
                                visible: isMobile

                                onCurrentItemChanged: {
                                    appSettings.showWalletState = (currentItem.objectName === "EstimateBalance") ? 0 : 1
                                    console.log("changed wallet state new state", appSettings.showWalletState)
                                }

                                Item {
                                    objectName: "EstimateBalance"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 16
                                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                            visible: !loaderWithdrawal.visible

                                            DmsansText {
                                                Layout.preferredWidth: paintedWidth
                                                Layout.preferredHeight: paintedHeight
                                                text: "Estimated balance"
                                                color: Colors.grape_gray_color
                                                font.pixelSize: 14
                                            }

                                            IconText {
                                                id: showHideVisibleWallet
                                                Layout.preferredWidth: Layout.preferredHeight
                                                Layout.preferredHeight: 16
                                                font.pixelSize: 14
                                                text: !securityState ? IcoMoon.visability : IcoMoon.lock_close
                                                color: Colors.grape_gray_color

                                                MouseArea {
                                                    anchors.centerIn: showHideVisibleWallet
                                                    width: 32
                                                    height: 32
                                                    onPressed: etUtils.vibrate()
                                                    onClicked: {
                                                        securityState = !securityState
                                                        console.log("pressed show hide, Current state " + securityState ? "\'secured\'" : "\'unsafe\'")
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.preferredHeight: 40
                                            Layout.fillWidth: true
                                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft

                                            DmsansText {
                                                id: estimatedBalanceText
                                                Layout.preferredWidth: paintedWidth
                                                Layout.preferredHeight: 40
                                                text: Utils.mask((Number(estimateBalance).toFixed(3) == "NaN" ? "~" : Number(estimateBalance).toFixed(3)) + " ExC", securityState)
                                                color: Colors.def_color_text
                                                font.pixelSize: 28
                                                font.bold: true
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
                                                visible: !isOnboardingState
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 40
                                                visible: !isMobile
                                            }
                                        }
                                    }
                                }

                                Item {
                                    objectName: "WalletBalance"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 16
                                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                            visible: !loaderWithdrawal.visible

                                            DmsansText {
                                                Layout.preferredWidth: paintedWidth
                                                Layout.preferredHeight: paintedHeight
                                                text: "Current wallet balance"
                                                color: Colors.grape_gray_color
                                                font.pixelSize: 14
                                            }

                                            IconText {
                                                id: showHideVisibleCurrentWallet
                                                Layout.preferredWidth: Layout.preferredHeight
                                                Layout.preferredHeight: 16
                                                font.pixelSize: 14
                                                text: !securityState ? IcoMoon.visability : IcoMoon.lock_close
                                                color: Colors.grape_gray_color

                                                MouseArea {
                                                    anchors.centerIn: showHideVisibleCurrentWallet
                                                    width: 32
                                                    height: 32
                                                    onPressed: etUtils.vibrate()
                                                    onClicked: {
                                                        securityState = !securityState
                                                        console.log("pressed show hide, Current state " + securityState ? "\'secured\'" : "\'unsafe\'")
                                                    }
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.preferredHeight: 40
                                            Layout.fillWidth: true
                                            Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft

                                            DmsansText {
                                                id: currentWalletBalanceText
                                                Layout.preferredWidth: paintedWidth
                                                Layout.preferredHeight: 40
                                                property string currentBalance: "~"
                                                text: Utils.mask((Number(currentBalance).toFixed(3) == "NaN" ? "~" : Number(currentBalance).toFixed(3)) + " ExC", securityState)
                                                color: Colors.def_color_text
                                                font.pixelSize: 28
                                                font.bold: true
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
                                                visible: !isOnboardingState

                                                Connections {
                                                    target: walletUIController

                                                    function onEstimatedBalanceChanged() {
                                                        if(appSettings.selectedWallet === "" || appSettings.selectedWallet === "~") {
                                                            currentWalletBalanceText.currentBalance = walletModel.get(0).balance
                                                            currentWalletBalanceText.text = Utils.mask(currentWalletBalanceText.currentBalance + " ExC", securityState)
                                                        }

                                                        for(let i = 0; i < walletModel.rowCount(); i++) {
                                                            if(walletModel.get(i).wallet_id === appSettings.selectedWallet) {
                                                                currentWalletBalanceText.currentBalance = walletModel.get(i).balance
                                                                if(currentWalletBalanceText.currentBalance === "~")
                                                                    return;
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 40
                                                visible: !isMobile
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                visible: !isMobile
                                anchors.fill: parent

                                ColumnLayout {
                                    anchors.fill: parent

                                    RowLayout {
                                        id: clWalletInfoDesktop
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 66

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 40

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 16
                                                Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                                visible: !loaderWithdrawal.visible

                                                DmsansText {
                                                    Layout.preferredWidth: paintedWidth
                                                    Layout.preferredHeight: paintedHeight
                                                    text: "Estimated balance"
                                                    color: Colors.grape_gray_color
                                                    font.pixelSize: 14
                                                }

                                                IconText {
                                                    Layout.preferredWidth: Layout.preferredHeight
                                                    Layout.preferredHeight: 16
                                                    font.pixelSize: 14
                                                    text: !securityState ? IcoMoon.visability : IcoMoon.lock_close
                                                    color: Colors.grape_gray_color

                                                    MouseArea {
                                                        anchors.centerIn: parent
                                                        width: 32
                                                        height: 32
                                                        onPressed: etUtils.vibrate()
                                                        onClicked: {
                                                            securityState = !securityState
                                                            console.log("pressed show hide, Current state " + securityState ? "\'secured\'" : "\'unsafe\'")
                                                        }
                                                    }
                                                }
                                            }

                                            RowLayout {
                                                Layout.preferredHeight: 40
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignLeft
                                                visible: !isMobile

                                                DmsansText {
                                                    Layout.preferredWidth: paintedWidth
                                                    Layout.preferredHeight: 40
                                                    text: Utils.mask((Number(estimateBalance).toFixed(3) == "NaN" ? "~" : Number(estimateBalance).toFixed(3)) + " ExC", securityState)
                                                    color: Colors.def_color_text
                                                    font.pixelSize: 28
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
                                                    visible: !isOnboardingState
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    visible: !isMobile
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    Layout.minimumWidth: 85
                                                    Layout.preferredWidth: 300
                                                    Layout.maximumWidth: 330
                                                    visible: !isMobile
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 40

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 16
                                                Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft
                                                visible: !loaderWithdrawal.visible

                                                DmsansText {
                                                    Layout.preferredWidth: paintedWidth
                                                    Layout.preferredHeight: paintedHeight
                                                    text: "Current wallet balance"
                                                    color: Colors.grape_gray_color
                                                    font.pixelSize: 14
                                                }
                                            }

                                            RowLayout {
                                                Layout.preferredHeight: 40
                                                Layout.fillWidth: true
                                                Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignLeft

                                                DmsansText {
                                                    Layout.preferredWidth: paintedWidth
                                                    Layout.preferredHeight: 40
                                                    property string currentBalance: "~"
                                                    property bool inited: false
                                                    text: currentWalletBalanceText.text
                                                    color: Colors.def_color_text
                                                    font.pixelSize: 28
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
                                                    visible: !isOnboardingState
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 40
                                                    visible: !isMobile
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        id: desktopDepositAndWithdrawItem
                                        Layout.preferredWidth: 320
                                        Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignRight
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 15
                            visible: isMobile

                            PageIndicator {
                                id: indicator

                                count: view.count
                                currentIndex: view.currentIndex
                                anchors.bottom: view.bottom
                                anchors.horizontalCenter: parent.horizontalCenter

                                delegate: Rectangle {
                                    implicitWidth: 8
                                    implicitHeight: 8
                                    radius: width / 2
                                    color: (index === view.currentIndex) ? Colors.isDarkTheme ? "white" : "#6B6E70" : Colors.isDarkTheme ? "#6B6E70" : "#A4A4A4"
                                }
                            }
                        }

                        Item {
                            id: mobileDepositAndWithdrawItem
                            Layout.preferredHeight: 40
                            Layout.fillWidth: isMobile
                            visible: isMobile
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            spacing: 4
                            visible: false

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                visible: !isMobile
                            }

                            WalletQuickButton {
                                Layout.preferredHeight: 72
                                Layout.preferredWidth: isMobile ? 104 : 204
                                Layout.maximumWidth: Layout.preferredWidth + 20
                                Layout.minimumWidth: isMobile ? 80 : 80
                                Layout.fillWidth: true
                                _icon: IcoMoon.plus
                                underText: root.width < 320 ? "Add new\nwallet" : "Add new wallet"
                                enabled: !walletUIController?.syncing || false
                                onClick: {
                                    console.log(`Pressed `, underText)
                                    loaderWithdrawal.sourceComponent = componentCreateWallet
                                    loaderWithdrawal.visible = true
                                }
                            }

                            WalletQuickButton {
                                Layout.preferredHeight: 72
                                Layout.preferredWidth: isMobile ? 104 : 204
                                Layout.maximumWidth: Layout.preferredWidth + 20
                                Layout.minimumWidth: isMobile ? 80 : 80
                                Layout.fillWidth: true
                                enabled: (!walletUIController?.syncing || false) && false
                                onClick: {
                                    console.log(`Pressed `, underText)
                                    notificationToolTip.showMessage("This feature is coming soon.")
                                }
                            }

                            WalletQuickButton {
                                Layout.preferredHeight: 72
                                Layout.preferredWidth: isMobile ? 104 : 204
                                Layout.maximumWidth: Layout.preferredWidth + 20
                                Layout.minimumWidth: isMobile ? 80 : 204
                                Layout.fillWidth: true
                                _icon: IcoMoon.settings
                                underText: "Manage\nsubscription"
                                enabled: !walletUIController?.syncing || false
                                onClick: {
                                    console.log(`Pressed `, underText)
                                    showSubscriptionPage()
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                visible: !isMobile
                            }
                        }
                    }
                }

                Rectangle {
                    id: walletBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: listWallet.contentHeight + 48
                    color: Colors.background
                    radius: 14
                    border.width: 1
                    border.color: Colors.border_color
                    visible: false

                    onVisibleChanged: {
                        if (visible) { // TODO: one load
                            walletUIController.renamesLoad()
                        }
                    }

                    ListView {
                        id: listWallet
                        anchors.centerIn: parent
                        width: parent.width
                        height: contentHeight
                        model: walletModel
                        interactive: false
                        clip: true
                        spacing: 10
                        property int _baseWidthColumn: root.isMobile ? 50 : 110
                        property real _balance: 0
                        currentIndex: -1
                        header: Item {
                            width: ListView.view.width
                            height: !root.isMobile ? 40 : 0
                            visible: !root.isMobile

                            RowLayout {
                                height: 40; x: 20
                                width: parent.width -10
                                anchors.centerIn: parent
                                spacing: 20

                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                }

                                DmsansText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    text: "Name"
                                    font.pixelSize: 14
                                    color: Colors.def_color_text
                                    horizontalAlignment: Text.AlignLeft
                                    verticalAlignment: Text.AlignVCenter
                                }

                                DmsansText {
                                    Layout.preferredWidth: listWallet._baseWidthColumn
                                    Layout.preferredHeight: 20
                                    horizontalAlignment: Text.AlignRight
                                    text: "Coin Price"
                                    color: Colors.def_color_text
                                    visible: false
                                }

                                DmsansText {
                                    Layout.preferredWidth: listWallet._baseWidthColumn
                                    Layout.preferredHeight: 20
                                    horizontalAlignment: Text.AlignRight
                                    text: "Balance"
                                    color: Colors.def_color_text
                                }

                                DmsansText {
                                    Layout.preferredWidth: listWallet._baseWidthColumn
                                    Layout.preferredHeight: 20
                                    horizontalAlignment: Text.AlignRight
                                    text: "Value"
                                    visible: false
                                    color: Colors.def_color_text
                                }

                                DmsansText {
                                    Layout.preferredWidth: listWallet._baseWidthColumn
                                    Layout.preferredHeight: 20
                                    horizontalAlignment: Text.AlignRight
                                    text: "24H change"
                                    visible: false
                                    color: Colors.def_color_text
                                }

                                Item {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 30
                                }
                            }
                        }
                        delegate: MouseArea {
                            width: ListView.view.width
                            height: 35
                            onClicked: {
                                listWallet.currentIndex = index
                                walletUIController.showWalletTransactions(model.wallet_id.toString(), appSettings.hideMining)
                                listWallet._balance = model.balance
                                selectedWallet = model.wallet_id.toString()
                                console.log("selected ", selectedWallet, "|", model.wallet_id.toString())
                            }

                            RowLayout {
                                x: 20
                                height: 40
                                width: parent.width -10
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: root.isMobile ? 10 : 20

                                Text{
                                    Layout.preferredWidth: 30
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    font.family: IcoMoon.iconmoon
                                    text: IcoMoon.raccoon
                                    font.pixelSize: 24
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Colors.raccoon_icon
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40

                                    MouseArea {
                                        id: walletNameItem
                                        width: parent.width
                                        height: (!editMode || statusText.text.length === 0) ? parent.height /2 : parent.height

                                        property string currentNameWallet: model.name
                                        property bool editMode: false
                                        property string cachedNameWallet: currentNameWallet
                                        property string newNameWallet
                                        property bool singleClicked: false

                                        Timer {
                                            id: checkDoubleTimer
                                            interval: 300
                                            repeat: false
                                            onTriggered: {
                                                if(walletNameItem.singleClicked) {
                                                    walletNameItem.singleClicked = false
                                                    walletUIController.showWalletTransactions(model.wallet_id.toString(), appSettings.hideMining)
                                                }
                                            }
                                        }

                                        onClicked: {
                                            if (walletNameItem.doubleClick) {
                                                console.log("double clicked")
                                            } else {
                                                singleClicked = true
                                                checkDoubleTimer.start()
                                            }
                                        }

                                        onDoubleClicked: {
                                            walletNameItem.singleClicked = false
                                            var message = qsTr("You copied wallet address %1.").arg(model.wallet_id)
                                            notificationToolTip.showMessage(message, Tooltip.CopiedAddress)
                                            walletUIController.copyWalletAddress(model.wallet_id)
                                        }

                                        DmsansText {
                                            id: walletNameText
                                            width: parent.width
                                            height: parent.height
                                            text: model.wallet_id // parent.currentNameWallet
                                            color: Colors.def_color_text
                                            font.pixelSize: 14
                                            verticalAlignment: Text.AlignBottom
                                            visible: !parent.editMode
                                            elide: Text.ElideRight
                                        }

                                        RaccoonTextField {
                                            id: editTF
                                            width: parent.width /2
                                            height: parent.height
                                            text: parent.currentNameWallet
                                            visible: parent.editMode
                                            onTextChanged: {
                                                parent.newNameWallet = text
                                            }
                                        }
                                    }

                                    DmsansText {
                                        id: statusText
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: text.length > 0 ? parent.height/2 : 0
                                        text: {
                                            let status
                                            switch(model.status) {
                                            case 1: status = "system"; break
                                            case 2: status = "main"; break
                                            case 3: status = "service"; break
                                            case 4: status = "DAppMaster"; break
                                            default: status = ""; break
                                            }

                                            return (model.name ? model.name : "") + (status ? (model.name ? " | " : "") + status : "")
                                        }
                                        color: Colors.def_color_text
                                        font.pixelSize: 12
                                        verticalAlignment: Text.AlignTop
                                        visible: !walletNameItem.editMode
                                    }
                                }

                                RowLayout {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: listWallet._baseWidthColumn
                                    visible: !root.isMobile

                                    // Item {
                                    //     id: coinPriceItemDesktop
                                    //     Layout.preferredWidth: listWallet._baseWidthColumn/2
                                    //     Layout.preferredHeight: 20
                                    // }

                                    Item {
                                        id: balanceItemDesktop
                                        Layout.preferredWidth: listWallet._baseWidthColumn
                                        Layout.preferredHeight: 20
                                    }

                                    // Item {
                                    //     id: valueItemDesktop
                                    //     Layout.preferredWidth: listWallet._baseWidthColumn
                                    //     Layout.preferredHeight: 20
                                    // }
                                }

                                Item {
                                    Layout.preferredHeight: 40
                                    Layout.preferredWidth: 120
                                    visible: root.isMobile

                                    // Item {
                                    //     id: priceItemMobile
                                    //     width: parent.width /2
                                    //     height: parent.height/2
                                    //     y: parent.height/2
                                    // }

                                    Item {
                                        id: balanceItemMobile
                                        width: parent.width
                                        height: parent.height
                                    }

                                    // Item {
                                    //     id: valueItemMobile
                                    //     width: parent.width /2
                                    //     height: parent.height/2
                                    //     y: parent.height/2
                                    //     x: parent.width/2
                                    // }
                                }

                                Item {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 30
                                    Layout.alignment: Qt.AlignVCenter
                                    SquareButton {
                                        id: editChangeBtn
                                        icon: IcoMoon.chat_settings
                                        width: parent.height
                                        koef_icon_size: 0.8
                                        anchors.centerIn: parent
                                        height: parent.height
                                        size: parent.height
                                        onClicked: {
                                            popup.name_wallet = model.name
                                            popup.id_wallet = model.wallet_id
                                            popup.index = index
                                            popup.printValues()
                                            popup.open()
                                        }
                                    }
                                }
                            }

                            DmsansText {
                                id: balanceText
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                                text: (model.balance === "~" ? "~.~~~" : Number(model.balance).toFixed(3)) + (!root.isMobile ? " ExC" : " E")
                                color: Colors.def_color_text
                                elide: Text.ElideRight
                                font.pixelSize: text_pixel_size

                            }

                            DmsansText {
                                id: coinPriceText
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignRight
                                text: "0.48$" // price_coin
                                color: Colors.def_color_text
                                elide: Text.ElideRight
                                font.pixelSize: text_pixel_size
                                visible: false
                            }

                            DmsansText {
                                id: valueText
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignRight
                                text: model.balance === "~" ? "~$" : (Number(model.balance) * 0.48).toFixed(2) + "$"
                                color: Colors.def_color_text
                                font.pixelSize: text_pixel_size
                                visible: false
                            }

                            states: [
                                State {
                                    name: "mobile_state"
                                    when: isMobile
                                    PropertyChanges { target: balanceText; parent: balanceItemMobile }
                                    // PropertyChanges { target: coinPriceText; parent: priceItemMobile }
                                    // PropertyChanges { target: valueText; parent: valueItemMobile }
                                },
                                State {
                                    name: "desktop_state"
                                    when: !isMobile
                                    PropertyChanges { target: balanceText; parent: balanceItemDesktop }
                                    // PropertyChanges { target: coinPriceText; parent: coinPriceItemDesktop }
                                    // PropertyChanges { target: valueText; parent: valueItemDesktop }
                                }
                            ]
                        }
                    }
                }

                Rectangle {
                    id: transactionsBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: clTansactions.implicitHeight + 48
                    color: Colors.background
                    radius: 14
                    border.width: 1
                    border.color: Colors.border_color

                    readonly property bool _hasTxs: txsModelList.model.count > 0 && !_is_syncing
                    visible: isOnboardingState ? true : !_is_syncing

                    Rectangle {
                        id: hideMenu
                        anchors.right: transactionsBox.right
                        anchors.rightMargin: 60
                        anchors.top: parent.top
                        anchors.topMargin: 24
                        width: 212
                        height: 40
                        visible: false
                        color: Colors.wallet.background
                        radius: 8
                        z: 100

                        RaccoonCheckBox {
                            id: hideMiningrewardCheckBox
                            anchors.fill: parent
                            text: "Hide mining reward"
                            font.pixelSize: 18
                            font.bold: true
                            onCheckedChanged: {
                                hideMenu.visible = false
                                walletUIController?.showWalletTransactions("", checked)
                                appSettings.hideMining = checked
                            }

                            Component.onCompleted: {
                                checked = appSettings.hideMining
                                // btnLoadHiddenTrx.pressendShowHiddeTrx = true
                            }
                        }
                    }

                    ColumnLayout {
                        id: clTansactions
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        anchors.topMargin: 10
                        anchors.bottomMargin: 24

                        RowLayout {
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true

                            DmsansText {
                                Layout.preferredWidth: paintedWidth
                                Layout.preferredHeight: 40
                                text: transactionsBox._hasTxs ? "Recent transactions" : "No transactions"
                                color: Colors.def_color_text
                                font.pixelSize: 18
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                visible: !isOnboardingState
                            }

                            Item {
                                Layout.preferredHeight: 40
                                Layout.fillWidth: true
                            }

                            SquareButton {
                                id: hideMinningRewBtn
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: 40
                                icon: IcoMoon.menu
                                koef_icon_size: 1.0
                                onClicked: {
                                    hideMenu.visible = !hideMenu.visible
                                }
                            }
                        }

                        ListView {
                            id: txsModelList
                            Layout.fillWidth: true
                            Layout.preferredHeight: contentHeight
                            model: isOnboardingState ? 10 : walletTxsModel
                            interactive: false
                            clip: true
                            spacing: 10
                            visible: !isOnboardingState ? transactionsBox._hasTxs && !loaderWithdrawal.visible : true
                            enabled: !isOnboardingState
                            header: Item {
                                visible: !isMobile
                                width: ListView.view.width
                                height: visible ? 30 : 0
                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 5
                                    DmsansText {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        leftPadding: 35
                                        text: "Name"
                                        color: Colors.grape_gray_color
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: parent.width * 0.1
                                        Layout.fillHeight: true
                                        text: "Value"
                                        color: Colors.grape_gray_color
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: parent.width * 0.15
                                        Layout.fillHeight: true
                                        text: "Status"
                                        color: Colors.grape_gray_color
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: 100
                                        Layout.fillHeight: true
                                        text: "Date and time"
                                        color: Colors.grape_gray_color
                                        font.pixelSize: 14
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            delegate: MouseArea {
                                width: ListView.view.width
                                height: isMobile ? clAmountAndDateTx.implicitHeight : 35
                                property var mModel: walletTxsModel.get(index)

                                onClicked: {
                                    if(securityState) {
                                        notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                                        return;
                                    }

                                    console.log("show tx data", mModel.hash, wallet, participant, dateTx, amount)
                                    txDetailedPopup.hash = mModel.hash
                                    txDetailedPopup.section = section
                                    txDetailedPopup.typeTx = mModel.typeTx
                                    txDetailedPopup.sender = wallet
                                    txDetailedPopup.participant = participant
                                    txDetailedPopup.date_time = dateTx
                                    txDetailedPopup.amount = amount
                                    txDetailedPopup.is_deposit = is_deposit
                                    txDetailedPopup.open()
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    visible: isMobile

                                    Text{
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 22
                                        Layout.alignment: Qt.AlignVCenter
                                        font.family: IcoMoon.iconmoon
                                        text: IcoMoon.raccoon
                                        font.pixelSize: 16
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Colors.raccoon_icon
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredHeight: implicitHeight
                                        spacing: 0
                                        DmsansText {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: paintedHeight
                                            text: Utils.mask(mModel.typeTx === 6 || mModel.typeTx === 4 ? "Mining reward" : "Raccoon", securityState)
                                            color: Colors.def_color_text
                                            elide: Text.ElideRight
                                            font.pixelSize: 16
                                        }

                                        DmsansText {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: paintedHeight
                                            text: Utils.mask("ExC", securityState)
                                            color: Colors.grape_gray_color
                                            elide: Text.ElideRight
                                            font.pixelSize: 14
                                        }
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: 100
                                        Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignVCenter
                                        text: statusTx
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 14
                                        color: Colors.def_color_text
                                    }

                                    ColumnLayout {
                                        id: clAmountAndDateTx
                                        Layout.preferredWidth: implicitWidth
                                        Layout.preferredHeight: implicitHeight
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 0

                                        DmsansText {
                                            Layout.preferredWidth: paintedWidth
                                            Layout.preferredHeight: paintedHeight
                                            Layout.alignment: Qt.AlignRight
                                            text: Utils.mask(isOnboardingState ? ((onboardingTransactionList[index] > 100  ? "+" : "-") + onboardingTransactionList[index])
                                                                               : (is_deposit ? "+" : "-") + Number(amount).toFixed(3), securityState)
                                            color: isOnboardingState ? onboardingTransactionList[index] > 100  ? Colors.green : Colors.red
                                            : securityState ? Colors.def_color_text
                                            : model.amount === "~" ? Colors.def_color_text : is_deposit ? Colors.green : Colors.red
                                            horizontalAlignment: Text.AlignRight
                                            font.pixelSize: 14
                                        }

                                        DmsansText {
                                            Layout.minimumWidth: 63
                                            Layout.preferredWidth: paintedWidth
                                            Layout.preferredHeight: paintedHeight
                                            Layout.alignment: Qt.AlignRight
                                            text: Utils.mask(formatDate(isOnboardingState ? 1750021200 : dateTx), securityState)
                                            color: Colors.def_color_text
                                            horizontalAlignment: Text.AlignRight
                                            font.pixelSize: 14
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 5
                                    visible: !isMobile

                                    Text{
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 22
                                        Layout.alignment: Qt.AlignVCenter
                                        font.family: IcoMoon.iconmoon
                                        text: IcoMoon.raccoon
                                        font.pixelSize: 16
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        color: Colors.raccoon_icon
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        DmsansText {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text: Utils.mask(mModel.typeTx === 6 || mModel.typeTx === 4 ? "Mining reward" : "Raccoon", securityState)
                                            font.pixelSize: 16
                                            color: Colors.def_color_text
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                        }
                                        DmsansText {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            text: Utils.mask("ExC", securityState)
                                            font.pixelSize: 14
                                            color: Colors.grape_gray_color
                                            elide: Text.ElideRight
                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: parent.width * 0.1
                                        Layout.minimumWidth: parent.width * 0.1
                                        Layout.preferredHeight: paintedHeight
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                        text: Utils.mask(isOnboardingState ? ((onboardingTransactionList[index] > 100  ? "+" : "-") + onboardingTransactionList[index])
                                                                           : (is_deposit ? "+" : "-") + Number(amount).toFixed(3), securityState)
                                        color: isOnboardingState ? onboardingTransactionList[index] > 100  ? Colors.green : Colors.red
                                        : securityState ? Colors.def_color_text
                                        : model.amount === "~" ? Colors.def_color_text : is_deposit ? Colors.green : Colors.red
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                        font.pixelSize: 14
                                    }

                                    DmsansText {
                                        Layout.preferredWidth: parent.width * 0.15
                                        Layout.minimumWidth: parent.width * 0.15
                                        Layout.preferredHeight: paintedHeight
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                        text: Utils.mask(isOnboardingState ? "Sended" : statusTx, securityState)
                                        color: Colors.def_color_text
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }

                                    DmsansText {
                                        Layout.minimumWidth: 90
                                        Layout.maximumWidth: 90

                                        Layout.preferredHeight: paintedHeight
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                        text: Utils.mask(formatDate(isOnboardingState ? 1750021200 : dateTx), securityState)
                                        color: Colors.def_color_text
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 14
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: topShadowRect
        anchors.horizontalCenter: parent.horizontalCenter
        height: 40
        width: parent.width - (2 * (isMobile ? 0 : 19))
        visible: false
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Colors.wallet.shadow
            }

            GradientStop {
                position: 0.7
                color: Colors.wallet.shadow_60p
            }

            GradientStop {
                position: 1.0
                color: Colors.wallet.shadow_20p
            }
        }
    }

    Rectangle{
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -2
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 14
        height: 40
        width: parent.width - (2 * (isMobile ? 0 : 19))
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Colors.wallet.shadow_20p
            }

            GradientStop {
                position: 0.3
                color: Colors.wallet.shadow_60p
            }

            GradientStop {
                position: 1.0
                color: Colors.wallet.shadow
            }
        }
    }

    function randomColor() {
        return "#" + Math.floor(Math.random()*16777215).toString(16).padStart(6, '0');
    }

    function formatDate(dateTx) {
        const txDate = new Date(Number(dateTx));
        const now = new Date();

        const isSameDay =
                        txDate.getDate() === now.getDate() &&
                        txDate.getMonth() === now.getMonth() &&
                        txDate.getFullYear() === now.getFullYear();

        if (isSameDay) {
            return txDate.toLocaleTimeString(Qt.locale(), "HH:mm");
        } else {
            return txDate.toLocaleString(Qt.locale(), "HH:mm<br>dd/MM/yy");
        }
    }

    RowLayout {
        id: rlDepositWithdraw
        anchors.fill: parent
        enabled: !_is_syncing

        BlueButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 40
            text: "Deposit"
            filled: true

            onClicked: {
                if(isOnboardingState)
                    return
                if(securityState) {
                    notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                    return;
                }
                console.log("clicked deposit")
                loaderWithdrawal.sourceComponent = componentDeposit
                loaderWithdrawal.visible = true
            }
        }

        DeepIndigoButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 40
            Layout.preferredHeight: 40
            text: "Withdraw"
            onClicked: {
                if(isOnboardingState)
                    return
                if(securityState) {
                    notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                    return;
                }
                console.log("pressed send")
                loaderWithdrawal.sourceComponent = componentWithdraw
                loaderWithdrawal.visible = true
            }
        }
    }

    states: [
        State { when:  isMobile; PropertyChanges { target: rlDepositWithdraw; parent: mobileDepositAndWithdrawItem  }},
        State { when: !isMobile; PropertyChanges { target: rlDepositWithdraw; parent: desktopDepositAndWithdrawItem }}
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: isMobile ? 0 : 15
        anchors.leftMargin: isMobile ? 0 : 18
        anchors.rightMargin: isMobile ? 0 : 18
        visible: selectWalletState

        onVisibleChanged: {
            if (visible) { // TODO: one load
                walletUIController.renamesLoad()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.leftMargin: isMobile ? 10 : 0
            Layout.rightMargin: isMobile ? 10 : 0

            SquareButton {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: width
                icon: IcoMoon.back
                z: 1000
                onClicked: {
                    walletUIController.showWalletTransactions(cachedWallet, appSettings.hideMining)
                    selectWalletState = false
                    editWalletState = false
                    if(menuDesktopWallet.visible)
                        menuDesktopWallet.visible = false
                }
            }

            DmsansText {
                anchors.centerIn: parent
                width: parent.width - 80
                height: paintedHeight
                text: "My wallets"
                color: Colors.def_color_text
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            DmsansText {
                anchors.right: parent.right
                height: parent.height
                width: paintedWidth + 20
                text: editWalletState ? "Done" : "Edit"
                color: editWalletState ? Colors.mining_text_color : Colors.def_color_text
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 16
                z: 1000
                visible: false

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        editWalletState = !editWalletState
                        if(menuDesktopWallet.visible)
                            menuDesktopWallet.visible = false
                    }
                }
            }
        }

        ScrollView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.horizontal.interactive: true
            ScrollBar.vertical.interactive: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: parent.width
                height: implicitHeight
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80

                    ColumnLayout {
                        width: parent.width - 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: implicitHeight
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        DmsansText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            color: Colors.grape_gray_color
                            text: "Net worth"
                            verticalAlignment: Text.AlignVCenter
                        }

                        DmsansText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 18
                            color: Colors.def_color_text
                            text: Utils.mask((Number(walletPage.estimateBalance).toFixed(3) == "NaN" ? "~" : Utils.mask(Number(walletPage.estimateBalance).toFixed(3)) + " ExC"), securityState)
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 32
                            font.bold: true
                            visible: !isOnboardingState
                        }
                    }

                    BlueButton {
                        id: addNewButtonInSelectWalletPageDesktop
                        width: 190
                        height: 40
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add new wallet"
                        filled: true
                        visible: !isMobile
                        onClicked: {
                            if(securityState) {
                                notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                                return
                            }

                            console.log("begin add new wallet")
                            console.log("begin add new wallet")
                            loaderWithdrawal.sourceComponent = componentCreateWallet
                            loaderWithdrawal.visible = true
                            raccoonController.componentCreateWalletNewWallet()
                        }
                    }
                }

                ListView {
                    id: selectWalletList
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    clip: true
                    model: walletModel
                    interactive: false
                    currentIndex: -1
                    onCountChanged: {
                        if(model.count > 0) {
                            currentIndex = 0
                            cachedWallet = model.get(currentIndex).wallet_id
                            selectedWallet = model.get(currentIndex).name ? model.get(currentIndex).name : model.get(currentIndex).wallet_id
                            walletUIController.showWalletTransactions(cachedWallet, appSettings.hideMining)
                        }
                    }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 64
                        color: index === selectWalletList.currentIndex ? Colors.wallet.selected_wallet : Colors.wallet.not_selected_wallet

                        MouseArea {
                            id: mouseWalletItemDelegate
                            anchors.fill: parent
                            onClicked: {
                                console.log("wallet clicked")
                                if(securityState) {
                                    notificationToolTip.showMessage(securityModeText)
                                    return;
                                }

                                if(popup.visible)
                                    popup.visible = false
                                if(menuDesktopWallet.visible)
                                    menuDesktopWallet.visible = false

                                selectWalletList.currentIndex = index
                                cachedWallet = model.wallet_id
                                selectedWallet = model.name ? model.name : model.wallet_id
                                walletUIController.showWalletTransactions(model.wallet_id, appSettings.hideMining)
                                selectWalletState = false
                                appSettings.selectedWallet = selectedWallet
                                currentWalletBalanceText.currentBalance = model.balance
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            Rectangle {
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: Layout.preferredHeight
                                radius: height/2
                                color: Colors.wallet.choose_wallet_background

                                DmsansText {
                                    anchors.centerIn: parent
                                    text: Utils.mask(modelIdText.text.slice(0, 2).toUpperCase(), securityState)
                                    color: Colors.grape_gray_color
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: implicitHeight
                                Layout.alignment: Qt.AlignVCenter

                                DmsansText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: paintedHeight
                                    text: Utils.mask(model.name ? model.name : "No name", securityState)
                                    color: Colors.def_color_text
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                DmsansText {
                                    id: modelIdText
                                    Layout.preferredWidth: 100
                                    Layout.preferredHeight: paintedHeight
                                    text: Utils.mask(model.wallet_id, securityState)
                                    color: Colors.grape_gray_color
                                    font.pixelSize: 14
                                    elide: Text.ElideMiddle
                                }
                            }

                            DmsansText {
                                Layout.fillHeight: true
                                Layout.preferredWidth: paintedWidth
                                verticalAlignment: Text.AlignVCenter
                                text: Utils.mask((model.balance === "~" ? "~.~~~" : Number(model.balance).toFixed(3)) + (!root.isMobile ? " ExC" : " E"), securityState)
                                color: Colors.def_color_text
                                font.pixelSize: 16
                                font.bold: true
                            }

                            SquareButton {
                                id: menuWallet
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: 30
                                Layout.alignment: Qt.AlignVCenter
                                icon: IcoMoon.menu
                                // visible: editWalletState
                                koef_icon_size: 1.0
                                onClicked: {
                                    console.log("Begin edit wallet")
                                    if(securityState) {
                                        notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                                        return;
                                    }

                                    if(popup.visible)
                                        popup.visible = false
                                    if(menuDesktopWallet.visible)
                                        menuDesktopWallet.visible = false

                                    // selectWalletList.currentIndex = index
                                    cachedWallet = model.wallet_id
                                    selectedWallet = cachedWallet
                                    walletUIController.showWalletTransactions(cachedWallet, appSettings.hideMining)

                                    if(isMobile) {
                                        editWalletPopup.id_wallet = model.wallet_id
                                        editWalletPopup.index = index
                                        editWalletPopup.name_wallet = model.name
                                        editWalletPopup.open()
                                    } else {
                                        const localPos = menuWallet.mapToItem(walletPage, mouseWalletItemDelegate.x, mouseWalletItemDelegate.y)
                                        console.log("localPos", localPos)
                                        menuDesktopWallet.x = localPos.x - menuDesktopWallet.width
                                        menuDesktopWallet.y = localPos.y
                                        menuDesktopWallet.wallet_address = model.wallet_id
                                        menuDesktopWallet.wallet_name = model.name
                                        menuDesktopWallet.wallet_index = index
                                        menuDesktopWallet.visible = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        BlueButton {
            Layout.preferredHeight: 50
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            filled: true
            text: "Add new wallet"
            visible: isMobile
            onClicked: {
                if(securityState) {
                    notificationToolTip.showMessage(securityModeText, Tooltip.Settings)
                    return;
                }
                console.log("begin add new wallet")
                loaderWithdrawal.sourceComponent = componentCreateWallet
                loaderWithdrawal.visible = true
                raccoonController.componentCreateWalletNewWallet()
            }
        }
    }

    BlackRectangle {
        id: onboardingShadow
        opacity: 0.2
        visible: !appSettings.onboard_finished
        z: 10
    }

    Rectangle {
        height: 22
        width: 100
        x: isMobile ? ((parent.width - width)/2) : parent.width - width - 18
        y: isMobile ? 80 : 18
        Layout.alignment: isMobile ? Qt.AlignHCenter : Qt.AlignRight
        color: Colors.wallet.select_wallet_background_button
        radius: height / 2
        visible: isOnboardingState
        z: onboarding_current_page === Onboarding.Wallet_Select ? 10000 : onboardingShadow.z - 1

        RowLayout {
            anchors.fill: parent
            DmsansText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 12
                leftPadding: 11
                elide: Text.ElideRight
                text: "Wallets"
                color: Colors.wallet.select_wallet_button
            }
            IconText {
                Layout.preferredHeight: 22
                Layout.preferredWidth: Layout.preferredHeight
                text: IcoMoon.down
                rotation: 270
                color: Colors.def_color_text
            }
        }
    }

    Item {
        id: recte
        y: isMobile ? (22 + 32 + 56 + 30)  : (78)
        x: isMobile ? ((parent.width - width) / 2) : 28
        width: estimatedBalanceText.width
        height: estimatedBalanceText.height
        visible: isOnboardingState

        DmsansText {
            anchors.fill: parent
            text: !isOnboardingState ? (Number(estimatedBalance).toFixed(3) == "NaN" ? "~" : Number(estimatedBalance).toFixed(3)) + " ExC"
                                     : "6988.677 ROCC"
            color: Colors.def_color_text
            font.pixelSize: 28
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
        }

        MouseArea {
            anchors.fill: parent

            onClicked: {
                const localPos = recte.mapToItem(walletPage, estimatedBalanceText.x, estimatedBalanceText.y)
                console.log(localPos)
            }
        }
    }

    function renameWallet(idWallet, nameWallet, index) {
        console.log("started rename wallet", idWallet, nameWallet, index)
        popup.id_wallet = idWallet
        popup.name_wallet = nameWallet
        popup.index = index
        popup.printValues()
        popup.open()
        editWalletState = false
    }

    MouseArea {
        anchors.fill: parent
        visible: menuDesktopWallet.visible || txDetailedPopup.visible
        onClicked: {
            console.log("Clicked")
            menuDesktopWallet.visible = false
            txDetailedPopup.visible = false
        }
    }

    OnboardingInformPanel {
        id: onboardingInformPanel
        anchors.fill: parent
        parent: tutorialInformationBoxForAllPlatform
    }

    Column {
        id: onborading_column
        x: onboarding_current_page === Onboarding.Wallet_Estimate_Balance ? (isMobile ? ((parent.width - width) / 2) : 50) :
                                                                            onboarding_current_page === Onboarding.Wallet_Transaction_List ? ((parent.width - width) / 2) :
                                                                                                                                             onboarding_current_page === Onboarding.Wallet_Select ? (isMobile ? ((parent.width - width) / 2) : (parent.width - width - 50))
                                                                                                                                                                                                  : 0

        y: onboarding_current_page === Onboarding.Wallet_Estimate_Balance ? recte.y + recte.height :
                                                                            onboarding_current_page === Onboarding.Wallet_Transaction_List && isMobile ? recte.y - 40 :
                                                                                                                                                         onboarding_current_page === Onboarding.Wallet_Select ? (isMobile ? recte.y - 38 : 44)
                                                                                                                                                                                                              : 0
        visible: !appSettings.onboard_finished
        width: 340
        height: implicitHeight
        spacing: 4
        z: visible ? 10000 : 0


        Repeater {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: onboarding_current_page === Onboarding.Wallet_Estimate_Balance || onboarding_current_page === Onboarding.Wallet_Select
            model: visible ? 7 : 0
            Rectangle {
                x:  onboarding_current_page === Onboarding.Wallet_Estimate_Balance && !isMobile ? 50 :
                                                                                                  onboarding_current_page === Onboarding.Wallet_Estimate_Balance && isMobile ? 170 :
                                                                                                                                                                               onboarding_current_page === Onboarding.Wallet_Select && isMobile ? 170 : 280
                width: 2
                height: 4
                color: Colors.onboarding.background
            }
        }

        Item {
            id: tutorialInformationBoxForAllPlatform
            width: 340
            height: onboardingInformPanel._implicitHeightInfo + 32
        }

        Repeater {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: onboarding_current_page === Onboarding.Wallet_Transaction_List
            model: visible ? 4 : 0
            Rectangle {
                x: 170
                width: 2
                height: 4
                color: Colors.onboarding.background
            }
        }
    }

    Rectangle {
        id: menuDesktopWallet
        width: 212
        height: clWalletMenu.implicitHeight + 30
        visible: false
        color: Colors.wallet.background
        radius: 8
        property string wallet_address
        property string wallet_name
        property int wallet_index

        ColumnLayout{
            id: clWalletMenu
            anchors.centerIn: parent
            height: implicitHeight
            width: parent.width - 32
            spacing: 34

            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                onClicked: {
                    walletUIController.copyWalletAddress(menuDesktopWallet.wallet_address)
                    menuDesktopWallet.visible = false
                    editWalletState = false
                    notificationToolTip.showMessage("ADDERESS COPIED TO CLIPBOARD", Tooltip.CopiedAddress)
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.copy
                        color: Colors.def_color_text
                        font.pixelSize: 16

                    }

                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Copy address"
                        font.pixelSize: 16
                    }
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                onClicked: {
                    popup.id_wallet = menuDesktopWallet.wallet_address
                    popup.name_wallet = menuDesktopWallet.wallet_name
                    popup.index = menuDesktopWallet.wallet_index

                    if (isMobile) {
                        //
                    } else {
                        popup.open()
                    }

                    menuDesktopWallet.visible = false
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.edit
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }

                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Rename wallet"
                        font.pixelSize: 16
                    }
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                visible: false

                onClicked: {
                    menuDesktopWallet.visible = false
                    editWalletState = false

                    if (!isNewProfile) {
                        showExportPage()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.key
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }

                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Export private key"
                        font.pixelSize: 16
                    }
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                visible: false
                onClicked: {
                    menuDesktopWallet.visible = false
                    editWalletState = false
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.down
                        color: Colors.def_color_text
                        font.pixelSize: 16
                    }

                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.def_color_text
                        text: "Export recovery phrase"
                        font.pixelSize: 16
                    }
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                visible: false
                onClicked: {
                    menuDesktopWallet.visible = false
                }

                RowLayout {
                    anchors.fill: parent
                    opacity: parent.pressed ? 0.7 : 1.0
                    IconText {
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: Layout.preferredHeight
                        text:  IcoMoon.trash
                        color: Colors.red
                        font.pixelSize: 16
                    }

                    DmsansText {
                        Layout.preferredHeight: 22
                        Layout.fillWidth: true
                        color: Colors.red
                        text: "Delete"
                        font.pixelSize: 16
                    }
                }
            }
        }
    }

    Rectangle {
        id: txDetailedDox
        width: isMobile ? parent.width - 30 : 300
        height: 200
        visible: false
        anchors.centerIn: parent
        color: Colors.wallet.background
        radius: 8
    }

    Popup {
        id: txDetailedPopup
        anchors.centerIn: parent
        width: isMobile ? parent.width - 20 : parent.width - 40
        height: clDetailedTx.implicitHeight + 100
        modal: true
        focus: true

        property string sender
        property string participant
        property string hash
        property string amount
        property string date_time
        property string section
        property int typeTx
        property bool is_deposit


        onVisibleChanged: {
            if(visible) {
            }
        }

        background: Rectangle {
            color: Colors.menuPopup.background
            radius: 15
            border.color: Colors.menuPopup.border
            border.width: 1
        }

        Overlay.modal: BlackRectangle { }

        contentItem: Rectangle {
            anchors.fill: parent
            radius: 8
            color: Colors.wallet.rename_wallet_background

            ColumnLayout{
                id: clDetailedTx
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 10
                spacing: 15

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    SquareButton {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: Layout.preferredHeight
                        icon: IcoMoon.down
                        koef_icon_size: 1.0
                        rotation: 90
                        pressed_color: selected || pressed ? Colors.grape_gray_color :  Colors.button_square_default_style.pressed_color_icon
                        onClicked: {
                            txDetailedPopup.close()
                        }
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: "Transfer details"
                        font.pixelSize: 18
                        font.bold: true
                        color: Colors.def_color_text
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Sender"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: txDetailedPopup.sender
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(txDetailedPopup.sender)
                                notificationToolTip.showMessage("Sender address was copied to clipboard", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Participant"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: txDetailedPopup.participant
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(txDetailedPopup.participant)
                                notificationToolTip.showMessage("Participant address was copied to clipboard", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Amount"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: (txDetailedPopup.is_deposit ? "+" : "-" ) + txDetailedPopup.amount
                        font.pixelSize: 14
                        font.bold: true
                        color: txDetailedPopup.is_deposit ? Colors.green : Colors.red

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(txDetailedPopup.amount)
                                notificationToolTip.showMessage("Transaction amount was copied to the clipboard.", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }


                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.minimumWidth: 150
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Section"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: txDetailedPopup.section
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(txDetailedPopup.section)
                                notificationToolTip.showMessage("Hash transaction was copied to clipboard", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.minimumWidth: 150
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Type"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: {
                            switch(txDetailedPopup.typeTx) {
                            case 0: return "Genesis"
                            case 1: return "Regular"
                            case 2: return "Contract Initialization"
                            case 3: return "Regular Repeatable"
                            case 4: return "Mining reward"
                            case 5: return "Burn"
                            case 6: return "Mining reward" // "Conversion"
                            case 99: return "Balance Saver"
                            default: return "Unknown"
                            }
                        }
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // walletUIController.copyWalletAddress(txDetailedPopup.section)
                                // notificationToolTip.showMessage("Section was copied to clipboard")
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        Layout.minimumWidth: 150
                        Layout.maximumWidth: clDetailedTx.width * 0.6
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Hash"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: txDetailedPopup.hash
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress(txDetailedPopup.hash)
                                notificationToolTip.showMessage("Hash transaction was copied to clipboard", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        text: "Date and time"
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text
                    }

                    DmsansText {
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        text: root.isMobile ? (new Date(Number(txDetailedPopup.date_time))).toLocaleString(Qt.locale(), "dd.MM.yy HH:mm:ss")
                                            : (new Date(Number(txDetailedPopup.date_time))).toLocaleString(Qt.locale(), "HH:mm:ss<br>dd.MM.yyyy")
                        font.pixelSize: 14
                        font.bold: true
                        color: Colors.def_color_text

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                walletUIController.copyWalletAddress((new Date(Number(txDetailedPopup.date_time))).toLocaleString(Qt.locale(), "dd.MM.yy HH:mm:ss"))
                                notificationToolTip.showMessage("Transaction date and time were copied to the clipboard.", Tooltip.CopiedAddress)
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }
    }

    Popup {
        id: popup
        anchors.centerIn: parent
        width: 300
        height: clRenameWallet.implicitHeight + 100
        modal: true
        focus: true

        property string id_wallet
        property string name_wallet
        property string index

        function printValues() {
            console.log("id_wallet:", id_wallet)
            console.log("name_wallet:", name_wallet)
            console.log("index:", index)
        }


        onVisibleChanged: {
            if(visible) {
                renameTF.text = name_wallet
            }
        }

        background: Rectangle {
            color: Colors.menuPopup.background
            radius: 15
            border.color: Colors.menuPopup.border
            border.width: 1
        }

        Overlay.modal: BlackRectangle { }

        contentItem: Rectangle {
            anchors.fill: parent
            radius: 8
            color: Colors.wallet.rename_wallet_background

            ColumnLayout{
                id: clRenameWallet
                anchors.fill: parent
                spacing: 15

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                DmsansText {
                    Layout.preferredHeight: 40
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "Rename wallet"
                    font.pixelSize: 18
                    font.bold: true
                    color: Colors.def_color_text
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                RaccoonTextField {
                    id: renameTF
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 260
                    Layout.alignment: Qt.AlignHCenter
                    text: popup.name_wallet
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.preferredHeight: 64
                    Layout.fillWidth: true
                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        onClicked: {
                            console.log("Clicked cancel")
                            popup.visible = false
                        }

                        DmsansText {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Colors.def_color_text
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        enabled: renameTF.text !== popup.name_wallet
                        onClicked: {
                            console.log("Clicked accept")
                            if (renameTF.text.length > 50) {
                                var message = qsTr("The wallet name must be shorter")
                                notificationToolTip.showMessage(message)
                                return
                            }
                            console.log(popup.id_wallet, renameTF.text, popup.index, popup.name_wallet)
                            walletUIController.renameWallet(popup.id_wallet, renameTF.text, popup.index)
                            popup.close()
                            renameTF.text = ""

                            if (!isNewProfile) {
                                showExportPage()
                            }
                        }
                        DmsansText {
                            anchors.centerIn: parent
                            text: "OK"
                            color: Colors.green
                            font.pixelSize: 16
                            font.bold: true
                            opacity: parent.enabled ? 1.0 : 0.7
                        }
                    }
                }
            }
        }
    }

    Component {
        id: componentWithdraw
        Withdraw {
        }
    }

    Component {
        id: componentTxStatus
        TxStatus {
            id: txStatus
            txStatus: true
        }
    }

    Component {
        id: componentTxStatusFailed
        TxStatus {
            id: txStatusFailed
            txStatus: false
        }
    }

    Component {
        id: componentDeposit
        Deposit {
        }
    }

    Component {
        id: componentCreateWallet
        CreateWallet {
            onBack: loaderWithdrawal.visible = false
        }
    }

    Component {
        id: componentSecureCode
        SecureCode {}
    }

    Component {
        id: componentStatusCreateWallet
        StatusCreateWallet {}
    }

    // Component {
    //     id: componentCreateToken
    //     CreateToken {}
    // }

    function showSubscriptionPage() {
        subscription.visible = true
    }

    Connections {
        target: raccoonController

        function onDagTxApproved(hash_tx) {
            if(root.sellected_window === MenuSelector.Wallet) {
                if(loaderWithdrawal.visible) {
                    notificationToolTip.showMessage("Transaction " + hash_tx + " sent for approval.")
                } else {
                    loaderWithdrawal.sourceComponent = componentTxStatus
                    loaderWithdrawal.visible = true
                }
            } else {
                notificationToolTip.showMessage("Transaction " + hash_tx + " sent for approval.")
            }
        }

        function onDagTxNotApproved(hash_tx) {
            if(root.sellected_window === MenuSelector.Wallet) {
                if(loaderWithdrawal.visible) {
                    notificationToolTip.showMessage("Transaction " + hash_tx + " has not approval.")
                } else {
                    loaderWithdrawal.sourceComponent = componentTxStatusFailed
                    loaderWithdrawal.visible = true
                }
            } else {
                notificationToolTip.showMessage("Transaction " + hash_tx + " has not approval.")
            }
        }
    }

    Connections {
        target: loaderWithdrawal.item

        function onNext() {
            notificationToolTip.showMessage("Transaction sent for approval.")
        }

        function onNextWallet(name_wallet, coin_name) {
            console.log("[onNextWallet]", name_wallet, coin_name)
            createWalletData.nameWallet = name_wallet
            createWalletData.currentCoin = coin_name
            loaderWithdrawal.sourceComponent = componentSecureCode
        }

        function onNextSecureCode() {
            raccoonController.addNewWallet(createWalletData.nameWallet, createWalletData.currentCoin)
        }

        function onCloseStatusCreateWallet() {
            console.log("close status create wallet")
            loaderWithdrawal.visible = false
        }
    }

    Connections {
        target: raccoonController
        function onWalletCreated() {
            console.log("wallet created. Function on qml.")
            loaderWithdrawal.sourceComponent = componentStatusCreateWallet
            loaderWithdrawal.item.runTimerToClosePage()
            loaderWithdrawal.visible = true
        }

        function onFailedTxCreate(expError) {
            console.log("transaction create failed. Tx is empty or not approved.")
            loaderWithdrawal.sourceComponent = componentTxStatusFailed
            loaderWithdrawal.item.expError = expError
            loaderWithdrawal.visible = true
        }

        // function onSendedTx() {
        //     loaderWithdrawal.sourceComponent = componentTxStatus
        //     loaderWithdrawal.visible = true
        // }

        function onErrorNameTokenExist(nameToken) {
            console.log("token by name ", nameToken, " exist");
        }

        function onErrorSymbolTokenExist(symbolToken) {
            console.log("token by symbol ", symbolToken, " exist");
        }
    }
}
