import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Fonts"

Rectangle {
    id: notificationToolTip
    width: Math.min(rl.implicitWidth + 28, root.width - 20)
    height: rl.implicitHeight + 20
    radius: 16
    color: Colors.notificationPopup.background
    border.color: Colors.notificationPopup.border
    visible: false
    anchors.horizontalCenter: parent.horizontalCenter
    y: !isMobile ? 0 : (root.height - 108 - height - (android_platform ? navigationHeight : 0))


    property string message: ""
    property int currentType: Tooltip.Message
    property string description

    Connections {
        target: raccoonController

        function onExportImportKeystore(newMessage) {
            showMessage(newMessage)
        }

        function onDecryptedKeystore(hasHash, message) {
            if(message.length > 0) {
                showMessage(message)
            }
        }

        function onErrorNameTokenExist(nameToken) {
            console.log("[NotificationToolTip] token by name ", nameToken, " exists");
            var message = "Token by name " + nameToken + " exists."
            showMessage(message)
        }

        function onErrorSymbolTokenExist(symbolToken) {
            console.log("[NotificationToolTip] token by symbol ", symbolToken, " exists");
            var message = "Token by symbol " + symbolToken + " exists."
            showMessage(message)
        }

    }

    Connections {
        target: uiController

        function onResultAddFile(result, file) {
            if (result.substring(0, 5) === 'Error') {
                console.log("mainWindow.tooltipMsg(result, 1500)")
                showMessage(result)
            }
            else {
                console.log("mainWindow.tooltipMsg(file, 1500)")
                showMessage(result, Tooltip.UploadFile)
            }
        }

        function onUsernameActiveChanged() {
            if (isMessenger) {
                messengerPage.loadMessenger()
            }
        }
    }

    Connections {
        target: walletUIController

        function onSubscribtionActive() {
            showMessage("Subscription activated")
        }

        function onMessage(message) {
            if(message.indexOf("mining reward coins") !== -1 && appSettings.hideMining) {
                return;
            }
            showMessage(message, Tooltip.Mining)
        }
    }

    Connections {
        target: messengerController

        function onNewChatAdded(actor) {
            var message = "Added new chat from " + actor
            showMessage(message)
        }

        function onNewMessageAdded(actor) {
            var message = "New message from " + actor
            showMessage(message)
        }

        function onError(msg) {
            showMessage(msg)
        }

        function onExported(msg) {
            showMessage(msg, Tooltip.Withdraw)
        }
    }

    Connections {
        target: dfsFileFilterModel

        function onMessage(message) {
            showMessage(message)
        }
    }

    Connections {
        target: root

        function onSecurityStateChanged() {
            const message = "Stealth mode has been " + (securityState ? "enabled." : "disabled.")
            showMessage(message)
        }
    }

    Connections {
        target: filePicker

        function onCopied() {
            notificationToolTip.message = "File exported"
            showMessage("File exported", Tooltip.Withdraw)
        }

        function onMessage(message) {
            showMessage(message)
        }
    }

    function showMessage(message, type = Tooltip.Message, description = "") {
        if(isOnboardingState) {
            return
        }

        if (message === undefined || message === null) {
            if (notificationToolTip.message.length === 0)
                return
        } else {
            notificationToolTip.message = message
            notificationToolTip.currentType = type
            notificationToolTip.description = description
        }

        notificationToolTip.state = "visible"
        notificationToolTip.visible = true
        timerShowMessage.start()
    }

    RowLayout {
        id: rl
        anchors.fill: parent
        anchors.leftMargin: 14
        Rectangle {
            Layout.preferredHeight: 38
            Layout.preferredWidth: Layout.preferredHeight
            Layout.alignment: Qt.AlignVCenter
            color: Colors.notificationPopup.icon_placeholder
            radius: height/2

            Image {
                anchors.centerIn: parent
                width: 24
                height: 24
                source: {
                    switch(currentType) {
                    case Tooltip.Deposit: return "qrc:/new_design/UI/Images/new_design/deposited.svg"
                    case Tooltip.Withdraw: return "qrc:/new_design/UI/Images/new_design/withdraw.svg"
                    case Tooltip.Mining: return "qrc:/new_design/UI/Images/new_design/mining.svg"
                    case Tooltip.Settings: return "qrc:/new_design/UI/Images/new_design/settings.svg"
                    case Tooltip.CopiedAddress: return "qrc:/new_design/UI/Images/new_design/check.svg"
                    case Tooltip.UploadFile: return "qrc:/new_design/UI/Images/new_design/upload.svg"
                    default: return "qrc:/new_design/UI/Images/new_design/check.svg"
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            DmsansText {
                Layout.fillWidth: true
                Layout.preferredHeight: paintedHeight
                text: message
                color: Colors.def_color_text
                font.weight: 700
                font.pixelSize: 14
                wrapMode: Text.Wrap
            }

            DmsansText {
                Layout.fillWidth: true
                Layout.preferredHeight: paintedHeight * visible
                text: description
                color: Colors.notificationPopup.description
                font.weight: 500
                font.pixelSize: 14
                wrapMode: Text.Wrap
                visible: text.length > 0
            }
        }

        SquareButton {
            Layout.preferredHeight: 38
            Layout.preferredWidth: Layout.preferredHeight
            Layout.alignment: Qt.AlignVCenter
            icon: IcoMoon.close
            onClicked: {
                notificationToolTip.visible = false
            }
        }
    }

    state: "visible"
    states: [
        State {
            name: "visible"
            PropertyChanges {
                target: notificationToolTip
                opacity: 1.0
            }
        },
        State {
            name: "unvisible"
            PropertyChanges {
                target: notificationToolTip
                opacity: 0.0
            }
        }
    ]

    transitions: Transition {
        NumberAnimation { properties: "property"; from: 1.0; duration: 0.0 }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            notificationToolTip.state = "unvisible"
        }
    }

    Timer {
        id: timerShowMessage
        interval: 3000
        running: true
        onTriggered: {
            notificationToolTip.state = "unvisible"
            notificationToolTip.visible = false
        }
    }

    Timer {
        id: timerForTest
        interval: 3000
        repeat: true
        running: false
        onTriggered: {
            console.log("timer triggered")
            const randomType = Math.floor(Math.random() * 7);
            function getRandomText(minLength = 20, maxLength = 80) {
                const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
                const length = Math.floor(Math.random() * (maxLength - minLength + 1)) + minLength
                let result = ''
                for (let i = 0; i < length; i++) {
                    result += characters.charAt(Math.floor(Math.random() * characters.length))
                }
                return result
            }

            const title = getRandomText()
            const description = getRandomText()
            notificationToolTip.showMessage(title, randomType, description)
        }
    }
}
