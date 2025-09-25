import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ExtraChain 1.0

import "../Fonts"
import "../Controls"
import "../"

RaccoonPage {
    id: loginPage
    anchors.fill: parent
    color: Colors.background
    property bool isSignInStage: false
    property bool localNetwork: false

    property string keychainName: "Hash" + (etUtils.isRelease ? "" : "Debug")
    property string keychainHash
    property bool keychainReaded
    property bool keychainNeed
    property bool autologin: false
    property string pathToImportFile
    property string serverIp
    property string ios_data

    property string registration_current_ip
    property string registration_current_login
    property string registration_current_password
    property string registration_current_confirm_password
    property bool type_recovery_by_phase: false
    property bool type_recovery_by_hex: false
    property bool any_login_password
    property bool recovery_by_phrase_validated: false

    focus: true

    MouseArea { anchors.fill: parent }

    Connections {
        target: typeof keyChain !== "undefined" ? keyChain : null

        function onKeyStored(key) {
            console.log("[keyChain] Stored:", key)
        }

        function onKeyRestored(key, value) {
            console.log("[keyChain] Restored with data", key)
            keychainHash = value

            welcomePage.newUserHash(keychainHash)
            welcomePage.autoLogInStarted()
            console.log('[keyChain] Activated autologin')
        }

        function onKeyDeleted(key) {
            console.log("[keyChain] Deleted:", key)
            // Qt.quit()
        }

        function onError(errorText) {
            console.log("[keyChain] Error:", errorText)

            waiter.destroy()
        }
    }

    // TODO: Move position bindings from the component to the Loader.
    //       Check all uses of 'parent' inside the root element of the component.
    //       Rename all outer uses of the id "confirmPasswordTF" to "loader_Rectangle.item.confirmPasswordTF".
    //       Rename all outer uses of the id "loginTF" to "loader_Rectangle.item.loginTF".
    //       Rename all outer uses of the id "passwordTF" to "loader_Rectangle.item.passwordTF".
    //       Rename all outer uses of the id "ipTextField" to "loader_Rectangle.item.ipTextField".

    Timer {
        id: tempMsgLoad
        onTriggered: {
            if (isMessenger) {
                messengerPage.loadMessenger()
            }
        }
    }

    Connections {
        target: uiController
        // ignoreUnknownSignals: true

        function onAuthEnded(status, type) {
            console.log('--- Auth end')
            console.log("profile is new:", uiController.isNewProfile())
            isNewProfile = uiController.isNewProfile()
            logined = true
            importKeystoreMessageBox.close()

            if (keychainHash !== welcomePage.hash() && autologin) { // && keychainNeed
                console.log("[KeyStore] Write key [Autologin]", autologin)
                keyChain.writeKey(keychainName, welcomePage.hash())
            } else if(keychainHash !== welcomePage.hash() && !autologin){
                keyChain.deleteKey(keychainName)
            }

            if(ios_platform && appSettings.iosFaceIdLogin) {
                raccoonController.verifyWithFaceID()
            } else {
                loginPage.visible = false
                uiController.loadSubscription()
                uiController.loadUserName("")
                tempMsgLoad.start()
                raccoonController.fillMainActorData()
                keychainHash = ""
            }
        }

        function onLoginError(error) {
            autologinBox.started = false
            autologinAfterImportBox.started = false

            console.log('--- Login error', error)
            if (waiter !== null) {
                waiter.destroy()
            }

            let msgText
            switch(error) {
            case 0:
                msgText = "Invalid login or password"
                errorMessegeBox.title = "Incorrect email or password"
                errorMessegeBox.info_text = "The email or password you entered is incorrect. Please verify your credentials and try again."
                errorMessegeBox.open()
                break
            case 1:
                msgText = "No profiles files"
                errorMessegeBox.title = "Profiles not found"
                errorMessegeBox.info_text = "No matching profiles were found."
                errorMessegeBox.open()
                break
            case 2:
                msgText = "Multiple profiles found"
                const profiles = uiController.multipleProfiles()
                console.log('--- Multiple:', profiles)
                loader_Rectangle.sourceComponent = component_multiple
                multipleProfileInfoBox.open()
                loader_Rectangle.item.profiles = profiles
                break
            }

            // notificationToolTip.message = msgText
            // notificationToolTip.showMessage()
        }

        function onPrepare() {
            if (!uiController.isProfileEmpty()) {
                isSignInStage = true
            }

            if (Qt.platform.os === "osx" && !etUtils.isRelease && uiController.authHash) {
                console.log('--- Autologin')
                console.log('```', uiController.authHash)
                welcomePage.newUserHash(uiController.authHash)
                welcomePage.autoLogInStarted()
                console.log('[main.qml] autoLogin')
                return
            }

            if (!keychainReaded && !uiController.isProfileEmpty()) {
                keychainReaded = true
                console.log("[KeyStore] Read key", keychainName)
                keyChain.readKey(keychainName)
            }
        }

    }

    Connections {
        target: uiController
        function onLogout() {
            loginPage.visible = true
            currentPage = MenuSelector.Vpn
        }
    }

    Connections {
        target: raccoonController
        function onIosFaceAuth(result) {
            console.log("result faceid", result)
            if(result && loginPage.visible) {
                loginPage.visible = false
                uiController.loadSubscription()
                uiController.loadUserName("")
                tempMsgLoad.start()
                raccoonController.fillMainActorData()
                keychainHash = ""
            }
        }
    }

    Component {
        id: component_Rectangle

        RaccoonPage {
            color: Colors.background
            property alias loginTF: inner_loginTF
            property alias passwordTF: inner_passwordTF
            property alias confirmPasswordTF: inner_confirmPasswordTF
            property alias ipTextField: inner_ipTextField

            anchors.topMargin: Qt.platform.os === "osx" ? -root.SafeArea.margins.top : 0

            DevActivator {
                width: parent.width
                height: 100
            }

            ColumnLayout {
                id: cl
                anchors.centerIn: parent
                width: Math.min(loginPage.width -20, 480)
                height: implicitHeight
                spacing: root.isMobile ? 30 : 40

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 58
                    Layout.preferredWidth: 86
                    source: "qrc:/images/UI/Images/raccoonline.png"
                    antialiasing: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            notificationToolTip.showMessage(versionStr)
                        }
                    }
                }

                RaccoonTextField {
                    id: inner_loginTF
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: cl.width
                    placeholderText: "Login"
                    font.family: Montserrat.dmsans
                    font.pointSize: 16
                    focus: false

                    Component.onCompleted: {
                        if (!etUtils.isRelease) {
                            text = 'User'
                        }
                    }
                }

                RaccoonTextField {
                    id: inner_passwordTF
                    Layout.preferredWidth: cl.width
                    Layout.preferredHeight: 40
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                    error_border_width: 0

                    Component.onCompleted: {
                        if (!etUtils.isRelease) {
                            text = 'User'
                        }
                    }
                }

                RaccoonTextField {
                    id: inner_confirmPasswordTF
                    Layout.preferredWidth: cl.width
                    Layout.preferredHeight: 40
                    echoMode: TextInput.Password
                    placeholderText: "Confirm password"
                    visible: !isSignInStage

                    Component.onCompleted: {
                        if (!etUtils.isRelease) {
                            text = 'User'
                        }
                    }
                }

                RaccoonTextField {
                    id: inner_ipTextField
                    Layout.preferredHeight: 40
                    placeholderText: "First node"
                    Layout.preferredWidth: cl.width
                    font.pointSize: 16
                    focus: false
                    visible: UiSettings.debugMode
                    validator: RegularExpressionValidator {
                        regularExpression: /^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
                    }
                    text: etUtils.isRelease ? "51.68.181.52" : etUtils.serverIp()

                    onTextChanged: serverIp = text

                    function cleanIpAddress(ip) {
                        var parts = ip.split('.')
                        for (var i = 0; i < parts.length; i++) {
                            // Remove leading zeros
                            parts[i] = parts[i].replace(/^0+/, '')
                            // If the part is empty, replace it with '0'
                            if (parts[i] === '') {
                                parts[i] = '0'
                            }
                        }
                        return parts.join('.')
                    }

                    function validateIp(ip) {
                        var parts = ip.split('.')
                        if (parts.length !== 4) {
                            return false
                        }

                        for (var i = 0; i < parts.length; i++) {
                            var part = parseInt(parts[i])
                            if (isNaN(part) || part < 0 || part > 255) {
                                return false
                            }
                        }

                        return true
                    }
                }

                RowLayout {
                    spacing: 6
                    visible: UiSettings.debugMode
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: cl.width

                    DeepIndigoButton {
                        text: "public"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        onClicked: inner_ipTextField.text = "51.68.181.52"
                    }

                    DeepIndigoButton {
                        text: "test"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        onClicked: inner_ipTextField.text = "57.128.191.73"
                    }

                    DeepIndigoButton {
                        text: "local"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        onClicked: inner_ipTextField.text = "127.0.0.1"
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    BlueButton {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: cl.width
                        Layout.preferredHeight: 50
                        text: !isSignInStage ? "Register" : "Log In"
                        filled: true
                        enabled: (isSignInStage ? true : passwordTF.text.length >= 3) && chechFillInForSignUp()
                        onClicked: {
                            parent.runAction()
                        }
                    }

                    function runAction() {
                        console.log("start login", ipTextField.text, "ip:", etUtils.serverIp())
                        appSettings.onboard_finished = false
                        if (!isSignInStage) {
                            var ip = ipTextField.text
                            etUtils.setServerIp(ipTextField.text)

                            if (!ipTextField.validateIp(ip)) {
                                console.log("ip is not validate")
                                return;
                            }


                            registration_current_ip = ip
                            registration_current_login = inner_loginTF.text.trim()
                            registration_current_password = inner_passwordTF.text
                            registration_current_confirm_password = inner_confirmPasswordTF.text

                            loader_Rectangle.sourceComponent = component_registration
                        } else {
                            autologinBox.login = loginTF.text.trim()
                            autologinBox.password = passwordTF.text
                            autologinBox.open()
                        }
                    }

                    Item {
                        visible: root.isMobile
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 30
                    }

                    BlueButton {
                        Layout.preferredWidth: cl.width
                        Layout.preferredHeight: 50
                        text: "Import profile"
                        visible: root.isMobile
                        filled: true
                        onClicked: {
                            loader_Rectangle.sourceComponent = component_importKeystore
                        }
                    }

                    RowLayout {
                        Layout.preferredWidth: 300
                        spacing: 10

                        Text {
                            text: !isSignInStage ? "Already have an account?" : "Don't have an account?"
                            font.pointSize: 12
                            font.family: Montserrat.dmsans
                            color: Colors.def_color_text
                        }

                        DeepIndigoButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            text: !isSignInStage ? "Log In" : "Create account"
                            onClicked: {
                                parent.runAction()
                            }
                        }

                        function runAction() {
                            if (!isSignInStage && uiController.isProfileEmpty()) {
                                var mouseEvent = {
                                    x: 50,
                                    y: 50,
                                    button: Qt.LeftButton,
                                    buttons: Qt.LeftButton,
                                    modifiers: Qt.NoModifier,
                                    accepted: true
                                };

                                buttonImportProfile.clicked(mouseEvent)
                                return
                            }

                            console.log("Sign In button clicked")
                            isSignInStage = !isSignInStage;
                        }
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: localNetwork ? 50 : 0
                    text: localNetwork ? "Local network" : ""
                    horizontalAlignment: Text.AlignHCenter
                    color: "red"
                    font.family: Montserrat.dmsans
                }
            }

            Item {
                id: buttonImportProfileItemDesktop
                x: parent.width -170
                y: 40
                width: 150
                height: 50
            }

            DeepIndigoButton {
                id: buttonImportProfile
                anchors.fill: buttonImportProfileItemDesktop
                Layout.preferredWidth: Math.min(cl.width, 350)
                Layout.minimumWidth: Math.min(cl.width, 350)
                Layout.preferredHeight: 50
                text: "Import profile"
                visible: !root.isMobile
                onClicked: {
                    console.log("start import profile.")
                    loader_Rectangle.sourceComponent = component_importKeystore
                }
            }

            function chechFillInForSignUp() {
                if (isSignInStage) return true

                var login = inner_loginTF.text
                var password = inner_passwordTF.text
                var confirmPassword = inner_confirmPasswordTF.text
                var lenPassword = password.length
                var lenConfirmPassword = confirmPassword.length
                var minCountChars = 3
                return ((lenPassword === lenConfirmPassword)
                        && (lenPassword >= minCountChars
                            && lenConfirmPassword >= minCountChars)
                        && login.length >= minCountChars)
            }

        }
    }

    Component {
        id: component_importKeystore

        RaccoonPage {
            anchors.topMargin: Qt.platform.os === "osx" ? -root.SafeArea.margins.top : 0

            states: [
                State {
                    when: root.isMobile
                    PropertyChanges { target: selectButton; parent: itemSelectButtonMobile }
                    PropertyChanges { target: importButton; parent: itemImportButtomDesktop }

                },
                State {
                    when: !root.isMobile
                    PropertyChanges { target: selectButton; parent: itemSelectButtonDesktop }
                    PropertyChanges { target: importButton; parent: itemImportButtomDesktop }
                }
            ]

            MouseArea { anchors.fill: parent }

            BlueButton {
                id: selectButton
                anchors.fill: parent
                text: "Select File..."
                filled: true
                visible: !type_recovery_by_phase
                property string data: ""
                onClicked: {
                    console.log("start import profile.")
                    if(ios_platform)
                    {
                        filePicker.pickProfileFile()
                    } else {
                        tempFileDialog.open()
                    }
                }
            }

            function runAction() {
                console.log("start import profile.")
                if(ios_platform)
                {
                    filePicker.pickProfileFile()
                } else {
                    tempFileDialog.open()
                }
            }

            Connections {
                target: filePicker

                function onFilePicked(file_path, data) {
                    console.log("filePath: ", data)
                    var filePath = String(file_path);
                    let cleanPath = filePath.startsWith("file://") ? filePath.substring(7) : filePath;
                    console.log("Trying to read file at:", cleanPath);
                    pathToFencFileTF.text = cleanPath
                    ios_data = data
                }
            }

            BlueButton {
                id: importButton
                anchors.fill: parent
                enabled: pathToFencFileTF.text.length > 0 && loginEcrypt.text.length > 0 && passwordEcrypt.text.length > 0
                visible: !type_recovery_by_phase
                filled: true
                text: "Import"
                onClicked: {
                    importAction(pathToFencFileTF.text, loginEcrypt.text, passwordEcrypt.text)
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: root.isMobile ? (parent.width -20) : 500
                height: Math.min(implicitHeight, 600)
                spacing: root.isMobile ? 15 : 30

                Image {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 58
                    Layout.preferredWidth: 86
                    source: "qrc:/images/UI/Images/raccoonline.png"
                    antialiasing: true
                }

                ListView {
                    id: typeRecoveryList
                    Layout.preferredHeight: contentHeight + 50
                    Layout.fillWidth: true
                    clip: true
                    interactive: false
                    model: ["Restore Using File", "Restore Using Phrase", "Restore Using Hex"]
                    delegate: MouseArea {
                        width: typeRecoveryList.width
                        height: 30
                        onClicked: {
                            console.log("Pressed index:", index)
                            typeRecoveryList.currentIndex = index
                            switch(index) {
                            case 0: type_recovery_by_phase = false; type_recovery_by_hex = false; any_login_password = false; break;
                            case 1: type_recovery_by_phase = true; type_recovery_by_hex = false; any_login_password = true; break;
                            case 2: type_recovery_by_phase = true; type_recovery_by_hex = true; any_login_password = false; break;
                            }
                            loginEcrypt.text = ""
                            passwordEcrypt.text = ""
                            pathToFencFileTF.text = ""
                        }
                        RaccoonCheckBox {
                            anchors.fill: parent
                            text: modelData
                            checked: typeRecoveryList.currentIndex === index
                            enabled: false
                        }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: visible ? 40 : 0
                    spacing: root.isMobile ? 0 : 10
                    visible: !type_recovery_by_phase

                    RaccoonTextField {
                        id: pathToFencFileTF
                        Layout.preferredHeight: 40
                        Layout.fillWidth: true
                        font.family: Montserrat.dmsans
                        font.pointSize: 16
                        focus: false
                        enabled: text.length > 4
                        placeholderText: "Select Profile File for Import"
                    }

                    Item {
                        id: itemSelectButtonDesktop
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: root.isMobile ? 0 : 160
                    }
                }

                Item {
                    id: itemSelectButtonMobile
                    Layout.preferredHeight: visible ? 40 : 0
                    Layout.fillWidth: true
                    visible: root.isMobile && !type_recovery_by_phase
                }

                Item {
                    id: spaceItem
                    visible: root.isMobile && !type_recovery_by_phase
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: visible ? 0 : 0
                }


                // Rectangle {
                //     Layout.preferredHeight: visible ? 30 : 0
                //     Layout.fillWidth: true
                //     visible: !type_recovery_by_phase
                //     color: "red"
                // }

                DmsansText {
                    Layout.topMargin: -80
                    Layout.preferredHeight: paintedHeight
                    Layout.fillWidth: true
                    font.weight: 600
                    text: "Enter a " + (type_recovery_by_hex ? "Hex" : "Phrase") + " to Restore Profile"
                    color: Colors.def_color_text
                    font.pixelSize: 16
                    visible: type_recovery_by_phase
                }

                Item {
                    visible: root.isMobile && type_recovery_by_phase
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: visible ? 0 : 0
                }

                MouseArea {
                    Layout.topMargin: -100
                    id: hexBlock
                    Layout.fillWidth: true
                    Layout.preferredHeight: hexText.paintedHeight
                    visible: type_recovery_by_phase && hex.length > 0
                    property string hex: ""
                    onClicked: {
                        console.log("copy hex.")
                        walletUIController.copyWalletAddress(hex)
                    }

                    RowLayout {
                        anchors.fill: parent

                        DmsansText {
                            id: hexText
                            Layout.fillWidth: true
                            Layout.preferredHeight: paintedHeight
                            color: Colors.def_color_text
                            font.pixelSize: 12
                            text: "Hex Phrase: " + parent.parent.hex
                            wrapMode: Text.Wrap
                        }

                        IconText {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 30
                            text: IcoMoon.copy
                            color: Colors.def_color_text
                        }
                    }
                }

                Rectangle {
                    Layout.topMargin: -50
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? 120 : 0
                    radius: 4
                    color: Colors.background
                    border.width: 1
                    border.color: Colors.grape_gray_color
                    visible: type_recovery_by_phase

                    TextEdit {
                        id: mnemonicPhase
                        anchors.fill: parent
                        wrapMode: TextEdit.Wrap
                        padding: 8
                        font.pixelSize: 14
                        font.family: Montserrat.dmsans
                        color: Colors.def_color_text
                        property bool full_complete: false
                        property string lastValidText: ""
                        property var list: []

                        onTextChanged: {
                            recovery_by_phrase_validated = false
                            if (/\s{2,}/.test(text)) {
                                text = text.replace(/\s{2,}/g, " ");
                                cursorPosition = text.length;
                            }

                            let words = text.trim().split(/\s+/).filter(w => w.length > 0);
                            if (text.trim() === "") {
                                lastValidText = ""
                                return;
                            }
                            if (words.length <= 24) {
                                lastValidText = text
                                full_complete = check24words()
                                return;
                            }
                            if (words.length > 24 || text.length > lastValidText.length) {
                                text = lastValidText
                                cursorPosition = text.length
                                full_complete = check24words()
                            }
                        }

                        function check24words() {
                            let mnemonic = mnemonicPhase.text.trim()
                            let array = mnemonic.split(' ')
                            console.log(array.length, array)
                            if(array.length === 24) {
                                // mnemonicPhase.text = mnemonic
                                hexBlock.hex = uiController.importedHex(mnemonic)
                                return true
                            }
                            hexBlock.hex = ""
                            return false
                        }
                    }
                }

                ColumnLayout {
                    id: clLogin
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    spacing: 10

                    DmsansText {
                        Layout.preferredHeight: paintedHeight
                        Layout.fillWidth: true
                        font.weight: 600
                        text: "Enter%1Login and Password".arg(any_login_password ? " any " : " ")
                        color: Colors.def_color_text
                        font.pixelSize: 16
                        visible: type_recovery_by_hex || (recovery_by_phrase_validated && type_recovery_by_phase)
                                 || (!type_recovery_by_phase && pathToFencFileTF.text.length > 0)
                    }

                    RaccoonTextField {
                        id: loginEcrypt
                        Layout.preferredHeight: visible ? 40 : 0
                        Layout.fillWidth: true
                        font.family: Montserrat.dmsans
                        font.pointSize: 16
                        focus: false
                        visible: !type_recovery_by_phase ? pathToFencFileTF.text.length !== 0 : (type_recovery_by_hex || recovery_by_phrase_validated)
                        placeholderText: "Login"
                    }
                }

                RaccoonTextField {
                    id: passwordEcrypt
                    Layout.preferredHeight: visible ? 40 : 0
                    Layout.fillWidth: true
                    font.family: Montserrat.dmsans
                    font.pointSize: 16
                    focus: false
                    visible: !type_recovery_by_phase ? pathToFencFileTF.text.length !== 0 : (type_recovery_by_hex || recovery_by_phrase_validated)
                    placeholderText: "Password"
                    echoMode: TextInput.Password
                }

                BlueButton {
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 140
                    Layout.alignment: Qt.AlignHCenter
                    text: "Restore Profile"
                    filled: true
                    enabled: type_recovery_by_hex ? (mnemonicPhase.length > 0 && loginEcrypt.text.length > 0 && passwordEcrypt.text.length > 0) : mnemonicPhase.full_complete
                    visible: type_recovery_by_phase

                    property bool started
                    onClicked: {
                        if (!started) {
                            started = true
                        }

                        if (type_recovery_by_hex) {
                            const isSeedImported = uiController.importHex(loginEcrypt.text, passwordEcrypt.text, mnemonicPhase.text)
                            console.log("Import hex:", isSeedImported)

                            if (isSeedImported) {
                                welcomePage.email = loginEcrypt.text
                                welcomePage.password = passwordEcrypt.text

                                loginEcrypt.text = ""
                                passwordEcrypt.text = ""
                                mnemonicPhase.text = ""

                                // etUtils.setServerIp(serverIp)
                                welcomePage.isReg = false
                                settingsWindow.sellectedWindow = 0
                                welcomePage.logInStarted()
                            } else {
                                notificationToolTip.showMessage("Incorrect hex or login or password")
                            }

                            return
                        }

                        const isSeedValidated = uiController.validatePhrase(mnemonicPhase.text)
                        console.log("Validate phrase:", isSeedValidated)

                        if (isSeedValidated) {
                            // mnemonicPhase.text = ""
                            if (!recovery_by_phrase_validated) {
                                recovery_by_phrase_validated = true
                            } else {
                                enabled = false
                                let login = loginEcrypt.text.trim()
                                let password = passwordEcrypt.text.trim()
                                if (login === "" || password === "") {
                                    notificationToolTip.showMessage("Incorrect login or password format")
                                    return
                                }

                                const isSeedValidated = uiController.importPhrase(login, password, mnemonicPhase.text)
                                // mnemonicPhase.text = ""

                                if (!isSeedValidated) {
                                    notificationToolTip.showMessage("Incorrect phrase")
                                } else {
                                    welcomePage.email = login
                                    welcomePage.password = password

                                    mnemonicPhase.text = ""
                                    login = ""
                                    password = ""

                                    // etUtils.setServerIp(serverIp)
                                    welcomePage.isReg = false
                                    settingsWindow.sellectedWindow = 0
                                    welcomePage.logInStarted()
                                }
                            }
                        } else {
                            notificationToolTip.showMessage("Can't validate phrase")
                        }
                    }
                }

                Item {
                    id: itemImportButtomDesktop
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 40
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }

                Connections {
                    target: raccoonController

                    function onExportImportKeystore(newMessage) {
                        pathToFencFileTF.text = ""
                        loginEcrypt.text = ""
                        loginEcrypt.focus = false
                        passwordEcrypt.text = ""
                        loginEcrypt.focus = false
                    }
                }
            }

            FileDialog {
                id: tempFileDialog
                fileMode: FileDialog.OpenFile
                nameFilters: ["Profile (*.profile)"]
                onAccepted: {
                    var file = tempFileDialog.selectedFile
                    if(ios_platform) {
                        var filePath = String(file);
                        let cleanPath = filePath.startsWith("file://") ? filePath.substring(7) : filePath;
                        console.log("Trying to read file at:", cleanPath);
                        filePicker.readFileContents(cleanPath);
                        pathToFencFileTF.text = cleanPath
                    } else {
                        let path = Qt.resolvedUrl(file).toString()
                        path = path.replace("file://", "")

                        if (Qt.platform.os === "windows" && /^\/[A-Za-z]:/.test(path)) {
                            path = path.substring(1)
                        }

                        pathToFencFileTF.text = path
                    }
                }
            }

            BackButton {
                id: backToWallet
                x: root.isMobile ? 10 : 50
                y: root.isMobile ? 30 : 50
                text: "Back"
                onClickedBack: {
                    console.log("back to register page")
                    type_recovery_by_phase = false; type_recovery_by_hex = false; any_login_password = false
                    loader_Rectangle.sourceComponent = component_Rectangle
                }
            }
        }
    }

    Component {
        id: component_multiple

        RaccoonPage {
            anchors.topMargin: Qt.platform.os === "osx" ? -root.SafeArea.margins.top : 0

            color: Colors.background
            property var profiles: []

            MouseArea { anchors.fill: parent }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                anchors.bottom: profilesList.top; anchors.bottomMargin: 12
                text: 'Choose your address to start:'
                font.pixelSize: 15
                color: "white"
            }

            ListView {
                id: profilesList
                anchors.centerIn: parent
                boundsBehavior: Flickable.StopAtBounds
                width: 400; height: Math.min(50 * count, parent.height * 0.8)
                model: profiles ? JSON.parse(JSON.stringify(profiles)) : []
                spacing: 6

                delegate: BlueButton {
                    text: modelData
                    width: 400
                    height: 50
                    filled: true

                    onClicked: {
                        let m = modelData
                        loader_Rectangle.sourceComponent = component_Rectangle
                        uiController.logInTo(m)
                    }
                }
            }

            BackButton {
                id: backToWallet
                x: 50
                y: root.isMobile ? 30 : 50
                text: "Back"
                onClickedBack: {
                    console.log("back to login page")
                    loader_Rectangle.sourceComponent = component_Rectangle
                }
            }
        }
    }

    Component {
        id: component_registration

        SwipeView {
            id: view

            anchors.fill: parent
            anchors.topMargin: Qt.platform.os === "osx" ? -root.SafeArea.margins.top : 0
            interactive: false

            Item {
                id: firstPage

                RaccoonPage {
                    anchors.fill: parent
                    BackButton {
                        id: backToWallet
                        x: root.isMobile ? 10 : 50
                        y: root.isMobile ? 30 : 50
                        text: "Back"
                        onClickedBack: {
                            console.log("back to register page")
                            loader_Rectangle.sourceComponent = component_Rectangle
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        height: parent.height - 150
                        y: 150
                        width: Math.min(loginPage.width -20, 480)

                        DmsansText {
                            Layout.preferredHeight: paintedHeight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Registration"
                            color: Colors.def_color_text
                            font.pixelSize: 18
                            font.weight: 600
                        }

                        DmsansText {
                            Layout.preferredHeight: paintedHeight
                            Layout.fillWidth: true
                            color: Colors.def_color_text
                            text: "By creating an account, you acknowledge that:<br>• You are solely responsible for maintaining the security of your login credentials<br>• The company cannot recover access to your account if these credentials are lost
                             <br>• All actions performed using your account will be attributed to you<br><br>"
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        RaccoonCheckBox {
                            id: confirmationChackBox
                            Layout.preferredHeight: 30
                            Layout.fillWidth: true
                            text: "I understand and accept my responsibility for account security"
                            checked: false
                        }

                        Item {
                            Layout.preferredHeight: 20
                            Layout.fillWidth: true
                        }

                        RaccoonCheckBox {
                            id: autologinCheckBox
                            Layout.preferredHeight: 30
                            Layout.fillWidth: true
                            text: "Allow automatic sign-in on next use?"
                            checked: false
                        }


                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }


                        BlueButton {
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 140
                            Layout.alignment: Qt.AlignHCenter
                            text: "Registration"
                            filled: true
                            enabled: confirmationChackBox.checked

                            onClicked: {
                                enabled = false
                                autologin = autologinCheckBox.checked
                                view.incrementCurrentIndex()

                                settingsWindow.sellectedWindow = 0
                                welcomePage.startReg(registration_current_login, registration_current_password)
                                // console.log("User login", registration_current_ip, registration_current_login, registration_current_password, registration_current_confirm_password)

                                repeaterMnemonicPhase.model = uiController.getPhrase()
                                var fullPhrase = ""
                                var modelArray = repeaterMnemonicPhase.model
                                for (let i = 0; i < modelArray.length; ++i) {
                                    fullPhrase += modelArray[i] + ' '
                                }
                                hexExportBlock.hex = uiController.importedHex(fullPhrase)
                                console.log("hexExportBlock.hex", hexExportBlock.hex)
                                started = false
                            }
                        }
                    }
                }
            }

            Item {
                id: secondPage
                RaccoonPage {
                    anchors.fill: parent
                    BackButton {
                        x: root.isMobile ? 10 : 50
                        y: root.isMobile ? 30 : 50
                        text: "Back"
                        visible: false
                        onClickedBack: {
                            console.log("back to register page")
                            view.decrementCurrentIndex()
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        height: parent.height - 150
                        y: 150
                        width: Math.min(loginPage.width -20, 480)

                        DmsansText {
                            Layout.preferredHeight: paintedHeight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "Your Recovery Phrase"
                            color: Colors.def_color_text
                            font.pixelSize: 18
                            font.weight: 600
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        DmsansText {
                            Layout.preferredHeight: paintedHeight
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: "This is your unique 24-word recovery phrase. It is the only way to recover access to your profile.
Write it down and store it in a secure place — preferably offline and out of sight."
                            color: Colors.def_color_text
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        MouseArea {
                            id: hexExportBlock
                            Layout.fillWidth: true
                            Layout.preferredHeight: hexExportText.paintedHeight
                            visible: hex.length > 0
                            property string hex: ""
                            onClicked: {
                                console.log("copy hex.")
                                walletUIController.copyWalletAddress(hex)
                                notificationToolTip.showMessage("Hex copied")
                            }

                            RowLayout {
                                anchors.fill: parent

                                DmsansText {
                                    id: hexExportText
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: paintedHeight
                                    color: Colors.def_color_text
                                    font.pixelSize: 12
                                    text: "<b>Hex Phrase</b> (encrypted by login and password): " + hexExportBlock.hex
                                    wrapMode: Text.Wrap
                                }

                                IconText {
                                    Layout.preferredHeight: 40
                                    Layout.preferredWidth: 30
                                    text: IcoMoon.copy
                                    color: Colors.def_color_text
                                }
                            }
                        }

                        DmsansText {
                            text: 'or'
                            color: Colors.def_color_text
                        }

                        Flow {
                            Layout.topMargin: 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                            spacing: 4

                            Repeater {
                                id: repeaterMnemonicPhase

                                Rectangle {
                                    width: rlFlowDelegate.implicitWidth
                                    height: 24
                                    color: Colors.login_page.mnemonic_background
                                    border.color: Colors.grape_gray_color
                                    radius: 4

                                    RowLayout {
                                        id: rlFlowDelegate
                                        anchors.fill: parent
                                        spacing: 7

                                        DmsansText {
                                            Layout.leftMargin: 2
                                            Layout.preferredHeight: 24
                                            Layout.preferredWidth: paintedWidth
                                            leftPadding: 4
                                            text: index + 1
                                            font.pixelSize: 12
                                            color: Colors.green
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        DmsansText {
                                            Layout.rightMargin: 2
                                            Layout.preferredHeight: 24
                                            Layout.preferredWidth: paintedWidth
                                            rightPadding: 4
                                            text: modelData
                                            font.pixelSize: 12
                                            color: Colors.def_color_text
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        BlueButton {
                            id: registrationButton
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 180
                            Layout.alignment: Qt.AlignHCenter
                            text: "Copy Recovery Phrase"
                            filled: true
                            onClicked: {
                                console.log("Copy recovery phrase")
                                var fullPhrase = ""
                                var modelArray = repeaterMnemonicPhase.model
                                for (let i = 0; i < modelArray.length; ++i) {
                                    fullPhrase += modelArray[i] + ' '
                                }
                                console.log("Full phrase:", fullPhrase.trim())
                                walletUIController.copyWalletAddress(fullPhrase.trim())
                                notificationToolTip.showMessage("Recovery Phrase copied")
                            }
                        }

                        Item {
                            Layout.preferredHeight: 20
                            Layout.fillWidth: true
                        }

                        RaccoonCheckBox {
                            id: phase1
                            Layout.preferredHeight: 30
                            Layout.fillWidth: true
                            text: "I understand that if I lose my recovery phrase, I will permanently lose access to my profile and funds."
                            checked: false
                        }

                        Item {
                            Layout.preferredHeight: 20
                            Layout.fillWidth: true
                        }

                        RaccoonCheckBox {
                            id: phase2
                            Layout.preferredHeight: 30
                            Layout.fillWidth: true
                            text: "I understand that I must never share my recovery phrase with anyone"
                            checked: false
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }

                        BlueButton {
                            id: agreeRegistrationButton
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 140
                            Layout.alignment: Qt.AlignHCenter
                            text: "Continue"
                            filled: true
                            enabled: phase1.checked && phase2.checked

                            property bool started

                            onClicked: {
                                if (started) return
                                started = true

                                console.log("User agree")
                                autologin = autologinCheckBox.checked
                                view.decrementCurrentIndex()
                                raccoonController.sighUp(registration_current_ip, registration_current_login, registration_current_password, registration_current_confirm_password)
                                repeaterMnemonicPhase.model = []
                                // showExportPage()
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

    }

    Loader {
        id: loader_Rectangle
        sourceComponent: component_Rectangle
        anchors.fill: parent
        onLoaded: {
            if (sourceComponent === component_Rectangle) {
                // importKeystoreMessageBox.open()
            }
        }
    }

    Connections {
        target: raccoonController
        function onDecryptedKeystore(hashash) {
            console.log("decrypted store");
            if(!hashash){
                loader_Rectangle.sourceComponent = component_Rectangle
                console.log("beginimport5")
            }

            else
                loginPage.visible = false
        }
    }

    RaccoonMessageBox {
        id: messageBox
        title: "Registration"
        info_text: "By creating an account, you acknowledge that:
        • You are solely responsible for maintaining the security of your login credentials
        • The company cannot recover access to your account if these credentials are lost
        • All actions performed using your account will be attributed to you"
        check_box_text: "I understand and accept my responsibility for account security"
        use_check_box: true
        additional_question_text: "Allow automatic sign-in on next use?"

        property string login
        property string password
        property string confirmPassword
        property string ip
        property bool started

        onAgree: {
            if (started) return
            started = true

            console.log("User agree")
            autologin = status_additional_question

            settingsWindow.sellectedWindow = 0
            welcomePage.startReg(login, password)
            // console.log("User login", login, password)
            raccoonController.sighUp(ip, login, password, confirmPassword)
            showExportPage()
        }

        onCancel: {
            console.log("User reject")
        }
    }

    RaccoonMessageBox {
        id: importKeystoreMessageBox
        title: "Import keystore"
        info_text: "You can import an existing profile. Would you like to start the import?"
        use_check_box: false
        onAgree: {
            loader_Rectangle.sourceComponent = component_importKeystore
        }
    }

    RaccoonMessageBox {
        id: autologinBox
        title: "Sigh-in"
        info_text: "If you enable this option, the app will remember your login credentials and sign you in automatically the next time you open it.
Only use this on a private device you trust."
        use_check_box: false
        additional_question_text: "Allow automatic sign-in on next use?"

        agree_text: "Continue"
        property string login
        property string password

        property bool started

        onAgree: {
            if (started) return
            started = true

            welcomePage.email = login
            welcomePage.password = password
            welcomePage.isReg = false
            autologin = status_additional_question
            settingsWindow.sellectedWindow = 0
            welcomePage.logInStarted()

            console.log("status_additional_question", status_additional_question)
        }
    }

    RaccoonMessageBox {
        id: autologinAfterImportBox
        title: "Sigh-in"
        info_text: "Allow automatic sign-in on next use?"
        use_check_box: false
        additional_question_text: "Allow automatic sign-in on next use?"

        property string login
        property string password
        property bool started

        onAgree: {
            if (started) return
            started = true

            autologin = status_additional_question
            continueImport()
        }

        onCancel: {
            continueImport()
        }

        function continueImport() {
            if(ios_platform) {
                console.log("login:", autologinAfterImportBox.login, "password:", autologinAfterImportBox.password)
                raccoonController.importProfileForIos(ios_data, autologinAfterImportBox.login, autologinAfterImportBox.login)
            } else {
                console.log("login:", autologinAfterImportBox.login, "password:", autologinAfterImportBox.password)
                welcomePage.email = autologinAfterImportBox.login
                welcomePage.password = autologinAfterImportBox.password
                settingsWindow.sellectedWindow = 0
                var hash = raccoonController.importProfile(pathToImportFile, autologinAfterImportBox.login, autologinAfterImportBox.password)
            }
        }
    }

    RaccoonMessageBox {
        id: errorMessegeBox
        title: "Error Sigh-in"
        use_check_box: false
    }

    RaccoonMessageBox {
        id: requestLoginAndPassword
        title: "Import phrase"
        info_text: "Enter any login credentials — no verification required."
        use_check_box: false
        use_required_login_and_password: true
        property string mnemonicPhrase

        onAgree: {
            let login = entered_login.trim()
            let password = entered_password.trim()
            if (login === "" || password === "") {
                notificationToolTip.showMessage("Incorrect login or password format")
                return
            }

            const isSeedValidated = uiController.importPhrase(login, password, mnemonicPhrase)
            mnemonicPhrase = ""

            if (!isSeedValidated) {
                notificationToolTip.showMessage("Incorrect phrase")
            } else {
                welcomePage.email = login
                welcomePage.password = password

                mnemonicPhrase = ""
                login = ""
                password = ""
                clearLogin()

                welcomePage.isReg = false
                settingsWindow.sellectedWindow = 0
                welcomePage.logInStarted()
            }
        }
    }

    Connections {
        target: raccoonController
        function onShowMessageErrorBox(title, message) {
            errorBox.title = title
            errorBox.info_text = message
            errorBox.open()
            autologinAfterImportBox.started = false
        }

        function onExportImportKeystore(newMessage) {
            loader_Rectangle.sourceComponent = component_Rectangle
        }

        function onUpdateHash(hash) {
            console.log("updated", hash)
            if(autologin) {
                console.log("save autologin")
                keyChain.writeKey(keychainName, hash)
            } else {
                console.log("doesn't save autologin. delete keychain name.")
                keyChain.deleteKey(keychainName)
            }
        }
    }

    RaccoonMessageBox {
        id: errorBox
        use_check_box: false
    }

    RaccoonMessageBox {
        id: multipleProfileInfoBox
        use_check_box: false
        title: "Please select a profile."
        info_text: "The entered login and password correspond to multiple profiles. Please select the appropriate one from the list."
    }

    RaccoonPage {
        id: waiter
        anchors.fill: parent
        anchors.topMargin: Qt.platform.os === "osx" ? -root.SafeArea.margins.top : 0
        color: Colors.background
        visible: !uiController?.isProfileEmpty()
        activeAnimation: true

        MouseArea {
            anchors.fill: parent
            onPressed: if (isDesktop) root.startSystemMove()
        }

        Image {
            anchors.centerIn: parent
            height: 128
            width: 128
            source: "qrc:/UI/Images/extrachain_lite.png"
            antialiasing: true
        }
    }

    function importAction(path, login, password) {
        appSettings.onboard_finished = false
        console.log("start encrypt", path, login, password)
        etUtils.setServerIp(serverIp)
        var filePath = String(path)
        pathToImportFile = filePath.startsWith("file://") ? filePath.substring(7) : filePath;
        autologinAfterImportBox.login = login
        autologinAfterImportBox.password = password
        autologinAfterImportBox.open()
    }
}

