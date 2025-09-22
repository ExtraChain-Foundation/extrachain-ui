import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCore
import QtQuick.Dialogs
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Qt.labs.qmlmodels
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../Delegates"


Item {
    id: messengerRoot
    anchors.fill: parent
    visible: root.sellected_window === MenuSelector.Messenger

    readonly property string _time_format: "hh:mm"
    readonly property int _list_delegate_row_left_margin: 5
    readonly property int _radius: 8
    readonly property int _delegate_chat_width: chatList.width - chatScrollBar.width -1
    property bool reply_state: false
    property bool edit_state: false
    readonly property real _dark_k: 0.4
    readonly property real _bright_koef_from: 10
    readonly property real _bright_koef_to: -10
    property string cached_text_message

    onEdit_stateChanged: {
        if(!edit_state) {
            te.text = cached_text_message
            te.cursorPosition = te.text.length
        }
    }

    onVisibleChanged: {
        if (!visible) return

        userList.model = uiController.loadUserNames()
        // personProxyModel.sourceModel = messengerController.userModel
        chatProxyModel.sourceModel = messengerController.chatListModel

        messengerController.updateChatListModel()
    }

    function loadMessenger() {
        userList.model = uiController.loadUserNames()
        // personProxyModel.sourceModel = messengerController.userModel
        chatProxyModel.sourceModel = messengerController.chatListModel

        messengerController.updateChatListModel()
    }

    property string current_user

    Connections {
        target: root

        function onWidthChanged() {
            hideMenu()
        }

        function onHeightChanged() {
            hideMenu()
        }

        function onIsMobileChanged() {
            hideMenu()
        }

        function onSellected_windowChanged() {
            hideMenu()
        }
    }

    function hideMenu() {
        menuAddFile.visible = false
        menu.visible = false
        menuChat.visible = false
        gifMenu.visible = false
        screenshotImage.visible = false
        chatItem.visible = true
    }

    function replyTextByType(type, message) {
        switch(type) {
        case MessegeDelegateType.Text: return message;
        case MessegeDelegateType.Image: return "Image";
        case MessegeDelegateType.Video: return "Video " + messengerController?.getFileNameFromMessage(message);
        case MessegeDelegateType.Gif: return "Gif";
        case MessegeDelegateType.File: return "File " + messengerController?.getFileNameFromMessage(message);
        }
    }

    function darkenColor(inputColor, amount) {
        let r, g, b, a = 1.0

        if (typeof inputColor === "string") {
            if (inputColor.startsWith("#") && inputColor.length === 7) {
                r = parseInt(inputColor.slice(1, 3), 16) / 255
                g = parseInt(inputColor.slice(3, 5), 16) / 255
                b = parseInt(inputColor.slice(5, 7), 16) / 255
            } else {
                console.warn("Unsupported color format:", inputColor)
                return Qt.rgba(0, 0, 0, 1)
            }
        } else {
            r = inputColor.r
            g = inputColor.g
            b = inputColor.b
            a = inputColor.a
        }

        function clamp(v) {
            return Math.max(0, Math.min(1, v))
        }

        return Qt.rgba(
                    clamp(r * (1 - amount)),
                    clamp(g * (1 - amount)),
                    clamp(b * (1 - amount)),
                    a
                    )
    }

    function adjustBrightness(inputColor, percent) {
        let r, g, b, a = 1.0

        if (typeof inputColor === "string") {
            if (inputColor.startsWith("#") && inputColor.length === 7) {
                r = parseInt(inputColor.slice(1, 3), 16)
                g = parseInt(inputColor.slice(3, 5), 16)
                b = parseInt(inputColor.slice(5, 7), 16)
            } else {
                console.warn("Unsupported color format:", inputColor)
                return Qt.rgba(0, 0, 0, 1)
            }
        } else {
            r = inputColor.r * 255
            g = inputColor.g * 255
            b = inputColor.b * 255
            a = inputColor.a
        }

        r = Math.max(0, Math.min(255, r + r * percent / 100))
        g = Math.max(0, Math.min(255, g + g * percent / 100))
        b = Math.max(0, Math.min(255, b + b * percent / 100))

        return Qt.rgba(r / 255, g / 255, b / 255, a)
    }

    function colorFromText(text) {
        let hash = 0
        for (let i = 0; i < text.length; i++) {
            hash = text.charCodeAt(i) + ((hash << 5) - hash)
            hash = hash & hash
        }

        let color = "#"
        for (let i = 0; i < 3; i++) {
            const value = (hash >> (i * 8)) & 0xFF
            color += ("00" + value.toString(16)).slice(-2)
        }
        return color
    }

    Rectangle {
        id: listItem
        anchors.fill: parent
        color: Colors.background
        visible: (root.isMobile && swipeView.currentIndex === 0) || !root.isMobile

        SortFilterProxyModel {
            id: personProxyModel
            sourceModel: messengerController?.userModel || 0
            filters: [
                RegExpFilter {
                    roleName: "username"
                    pattern: textField.text
                    caseSensitivity: Qt.CaseInsensitive
                }
            ]

            sorters: [
                StringSorter { roleName: "username" }
            ]
        }

        SortFilterProxyModel {
            id: chatProxyModel
            sourceModel: messengerController?.chatListModel || 0

            sorters: [
                RoleSorter {
                    roleName: "has_messages"
                    ascendingOrder: false
                },
                RoleSorter {
                    roleName: "date_time_last_message"
                    ascendingOrder: false
                }
            ]
        }


        Item {
            width: parent.width -3
            height: parent.height

            Item {
                id: textFieldBox
                width: parent.width
                height: root.isMobile ? 40 : 44

                RaccoonTextField {
                    id: textField
                    width: parent.width
                    height: parent.height - 4
                    y: 2
                    anchors.bottom: parent.bottom
                    placeholderText: "Search"
                    font.family: Montserrat.monserrat
                    font.pointSize: isMobile ? 16 : 14
                    focus: false
                    _radius: messengerRoot._radius

                    onTextChanged: {
                        hideMenu()
                    }
                }
            }

            Rectangle {
                id: selectorChatsOrAllUsers
                anchors.top: textFieldBox.bottom
                anchors.topMargin: root.isMobile ? 5 : 4
                width: parent.width
                height: 40
                radius: _radius
                color: Colors.text_field_style.background
                property bool all_user_state: false

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.horizontalCenter
                    height: parent.height
                    onClicked: {
                        selectorChatsOrAllUsers.all_user_state = false
                        hideMenu()
                    }

                    IconText {
                        anchors.centerIn: parent
                        font.pixelSize: 28
                        text: IcoMoon.chatbox
                        color: Colors.checkBox.text
                        opacity: selectorChatsOrAllUsers.all_user_state ? 0.7 : 1.0
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: parent.height
                    width: 1
                }

                MouseArea {
                    anchors.left: parent.horizontalCenter
                    anchors.right: parent.right
                    height: parent.height

                    onClicked: {
                        selectorChatsOrAllUsers.all_user_state = true
                        hideMenu()
                    }

                    IconText {
                        anchors.centerIn: parent
                        font.pixelSize: 28
                        text: IcoMoon.community
                        color: Colors.checkBox.text
                        opacity: selectorChatsOrAllUsers.all_user_state ? 1.0 : 0.7
                    }
                }
            }

            ListView {
                id: userList
                anchors.fill: parent
                anchors.topMargin: textFieldBox.height + selectorChatsOrAllUsers.height + 8
                clip: true
                spacing: 1
                visible: selectorChatsOrAllUsers.all_user_state
                // model: personProxyModel
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: -1
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 3
                    rightPadding: 2
                    interactive: true
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: width / 2
                        color: Colors.messenger.scroll_bar
                        opacity: 0.8
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }

                property string current_user

                delegate: Rectangle {
                    height: 55
                    radius: _radius
                    width: userList.width
                    color: Colors.background // index === userList.currentIndex ? Colors.connect_zone : Colors.background

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: _list_delegate_row_left_margin
                        anchors.rightMargin: _list_delegate_row_left_margin

                        Rectangle {
                            Layout.preferredHeight: 36
                            Layout.preferredWidth: 36
                            Layout.alignment: Qt.AlignVCenter
                            radius: height / 2
                            color: colorFromText(modelData.username)
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: adjustBrightness(colorFromText(modelData.username), _bright_koef_from)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: adjustBrightness(colorFromText(modelData.username), _bright_koef_to)
                                }
                            }

                            MonserratText {
                                anchors.centerIn: parent
                                font.pixelSize: parent.height / 2
                                text: "M"/*modelData.username && modelData.username.length > 0 ? modelData.username[0].toUpperCase() : ""*/
                                layer.enabled: true
                                layer.effect: DropShadow {
                                    horizontalOffset: 1
                                    verticalOffset: 0
                                    radius: 6
                                    samples: 16
                                    color: Colors.default_shadow
                                }
                            }
                        }

                        MonserratText {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            text: raccoonController?.mainActor === modelData.actorId ? "Create mirror self-chat" : modelData.username
                            color: Colors.country_list_old.country_name
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            hideMenu()
                            if(uiController.loadUserName('').length === 0) {
                                change_username_box.open()
                                return;
                            }

                            userList.currentIndex = index
                            userList.current_user = modelData.actorId
                            var founded = false

                            var chats = chatsModel.model
                            for(var i = 0; i < chats.count; i++) {
                                var actorIdChat = chats.get(i).name_chat;
                                var nameChat = uiController.loadUserName(actorIdChat)
                                if(modelData.username === nameChat) {
                                    selectorChatsOrAllUsers.all_user_state = false
                                    chatsModel.current_file_actor_id = chats.get(i).fileActorId
                                    chatsModel.current_file_id = chats.get(i).fileId
                                    chatsModel.type = chats.get(i).type
                                    chatsModel.current_chat = nameChat
                                    chatsModel.currentIndex = i
                                    founded = true
                                }
                            }
                            if(founded)
                                return;

                            current_user = modelData.actorId
                            create_chat_message_box.current_index_of_users_list = index
                            create_chat_message_box.current_username = modelData.username
                            create_chat_message_box.open()
                            te.focus = true
                        }
                    }
                }
            }

            ListView {
                id: chatsModel
                anchors.fill: parent
                anchors.topMargin: textFieldBox.height + selectorChatsOrAllUsers.height + 8
                clip: true
                spacing: 1
                visible: !selectorChatsOrAllUsers.all_user_state
                model: messengerController.chatListModel // chatProxyModel
                property string current_chat
                property string current_chat_id
                property int type
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds

                property string current_file_actor_id
                property string current_file_id
                property var openSwipeDelegates: []

                delegate: SwipeDelegate {
                    id: swipeDelegate

                    height: 55
                    width: chatsModel.width

                    onClicked: {
                        hideMenu()
                        for (let i = 0; i < chatsModel.count; ++i) {
                            let item = chatsModel.itemAtIndex(i)
                            if (item && item !== swipeDelegate && item.swipe.opened) {
                                item.swipe.close();
                            }
                        }

                        chatsModel.current_chat = nameChatText.text
                        chatsModel.type = type
                        chatsModel.current_file_actor_id = fileActorId
                        chatsModel.current_file_id = fileId
                        chatsModel.currentIndex = index
                        var cached_message = messengerController?.getCachedMessage(name_chat)
                        te.text = cached_message
                        te.forceActiveFocus()

                        if (root.isMobile) {
                            // swipeView.incrementCurrentIndex()

                            for (let i = 0; i < chatsModel.openSwipeDelegates.length; ++i) {
                                let delegate = chatsModel.openSwipeDelegates[i];
                                if (delegate && delegate.swipe.opened) {
                                    delegate.swipe.close();
                                }
                            }
                            chatsModel.openSwipeDelegates = [];

                            if (isMobile)
                                inputMessageBox.visible = true
                            messengerController.updateChatModel(chatsModel.current_file_actor_id, chatsModel.current_file_id, chatsModel.type === 2)

                            if (root.isMobile) {
                                swipeView.incrementCurrentIndex()
                            }
                        }
                    }

                    swipe.onOpened: {
                        if (swipe.opened) {
                            chatsModel.currentIndex = index
                            for (let i = 0; i < chatsModel.count; ++i) {
                                let item = chatsModel.itemAtIndex(i)
                                if (item && item !== swipeDelegate && item.swipe.opened) {
                                    item.swipe.close();
                                }
                            }
                        }
                    }

                    background: Rectangle {
                        id: backgroundSwipeBox
                        radius: _radius
                        color: index === chatsModel.currentIndex ? Colors.connect_zone : Colors.background
                    }

                    swipe.right: Rectangle {
                        id: deleteButton
                        color: deleteMouseArea.pressed ? Qt.darker("tomato", 1.1) : visible ? "tomato" : backgroundSwipeBox.color
                        radius: _radius
                        visible: swipeDelegate.swipe.opened
                        height: parent.height
                        width: height
                        anchors.right: parent.right

                        IconText {
                            anchors.centerIn: parent
                            text: IcoMoon.trash
                            color: Colors.checkBox.text
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: deleteMouseArea
                            anchors.fill: parent
                            onClicked: {
                                console.log("pressed remove chat")
                                swipeDelegate.swipe.close()
                            }
                        }
                    }

                    contentItem: Item {

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: _list_delegate_row_left_margin
                            anchors.rightMargin: _list_delegate_row_left_margin
                            spacing: 5
                            Rectangle {
                                Layout.preferredHeight: 36
                                Layout.preferredWidth: 36
                                Layout.alignment: Qt.AlignVCenter
                                radius: height / 2
                                color: colorFromText(nameChatText.text)
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: adjustBrightness(colorFromText(nameChatText.text), _bright_koef_from)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: adjustBrightness(colorFromText(nameChatText.text), _bright_koef_to)
                                    }
                                }

                                MonserratText {
                                    anchors.centerIn: parent
                                    font.pixelSize: parent.height / 2
                                    text: nameChatText.text && nameChatText.text.length > 0 ? nameChatText.text[0].toUpperCase() : ""
                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        horizontalOffset: 1
                                        verticalOffset: 0
                                        radius: 6
                                        samples: 16
                                        color: Colors.default_shadow
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height
                                spacing: 0

                                MonserratText {
                                    id: nameChatText
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    font.pixelSize: 14
                                    text: name_chat === "Mirror" ? "Mirror" : uiController.loadUserName(name_chat)
                                    color: Colors.country_list_old.country_name
                                    verticalAlignment: Text.AlignBottom
                                    leftPadding: 4
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.preferredWidth: 14
                                    Layout.fillWidth: true

                                    MonserratText {
                                        id: msText
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        leftPadding: 5
                                        font.pixelSize: 11
                                        font.italic: true
                                        text: last_message
                                        color: Colors.messenger.day_separator_text
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    MonserratText {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: paintedWidth
                                        font.pixelSize: 11
                                        font.italic: true
                                        text: date_time_last_message > 0
                                              ? Qt.formatTime(
                                                    new Date(date_time_last_message),
                                                    Qt.locale().name.startsWith("en") ? (_time_format + " AP") : _time_format
                                                    )
                                              : "--:--"
                                        color: Colors.messenger.day_separator_text
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignRight
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: chatMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.LeftButton
                        visible: !root.isMobile

                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                console.log("Begin open menu chat.")
                                const localPos = chatMouse.mapToItem(messengerRoot, mouse.x, mouse.y)

                                menuChat.x = localPos.x
                                menuChat.y = localPos.y
                                hideMenu()
                                menuChat.visible = true
                            } else {
                                hideMenu()
                                chatsModel.currentIndex = index
                                chatsModel.current_chat = nameChatText.text
                                chatsModel.current_chat_id = name_chat
                                inputMessageBox.visible = true
                                chatsModel.type = type

                                var cached_message = messengerController?.getCachedMessage(name_chat)
                                te.text = cached_message
                                console.log("cached message", cached_message, name_chat)

                                chatsModel.current_file_actor_id = fileActorId
                                chatsModel.current_file_id = fileId
                                messengerController?.updateChatModel(fileActorId, fileId, type === 2)
                            }

                            te.forceActiveFocus()
                        }
                    }
                }
            }

            MonserratText {
                anchors.centerIn: parent
                text: !selectorChatsOrAllUsers.all_user_state ? qsTr("No chats yet") : qsTr("No users yet")
                color: Colors.detault_text_color
                font.pixelSize: 16
                visible: selectorChatsOrAllUsers.all_user_state ? userList.model.count === 0 : chatsModel.model.count === 0
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: 1
            color: Colors.text_field_style.background
            opacity: 0.8
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: chatItem
            anchors.fill: parent
            color: Colors.background
            visible: (root.isMobile && swipeView.currentIndex === 1) || !root.isMobile

            DropArea {
                id: dropArea
                anchors.fill: parent
                onEntered: {
                    drag.accepted = true
                }

                onDropped: {
                    for (var i = 0; i < drop.urls.length; ++i) {
                        var fileUrl = drop.urls[i];
                        console.log("Dropped file:", fileUrl);
                        var localPath = Qt.platform.os === "windows"
                                ? fileUrl.toString().replace("file:///", "")
                                : fileUrl.toString().replace("file://", "");
                        console.log("Local path:", localPath);
                        var list = []
                        list.push(localPath)
                        popupAddFiles.file = fileUrl
                        popupAddFiles.isFile = true
                        popupAddFiles.isImage = false
                        popupAddFiles.isVideo = false
                        popupAddFiles.nameFile = localPath
                        popupAddFiles.open()
                    }
                }
            }

            Item {
                id: userInfoItem
                width: parent.width
                height: root.isMobile ? 40 : 44
                visible: inputMessageBox.visible

                Rectangle {
                    width: parent.width
                    height: 40
                    anchors.bottom: parent.bottom
                    color: Colors.text_field_style.background
                    radius: _radius
                    visible: userInfo.text.length > 0

                    // MouseArea {
                    //     id: backButton
                    //     width: root.isMobile ? parent.height : 0
                    //     height: width
                    //     visible: root.isMobile

                    //     onClicked: {
                    //         if (root.isMobile)
                    //             swipeView.currentIndex = 0
                    //     }

                    //     IconText {
                    //         anchors.centerIn: parent
                    //         font.pixelSize: 28
                    //         text: IcoMoon.arrow_forward
                    //         color: Colors.checkBox.text
                    //         rotation: 180
                    //     }
                    // }

                    Rectangle {
                        id: avatar

                        anchors.left: parent.left//backButton.right
                        anchors.leftMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height * 0.9
                        width: height
                        radius: height / 2
                        color: "white"//colorFromText(chatsModel.current_chat)
                        // gradient: Gradient {
                        //     GradientStop {
                        //         position: 0.0
                        //         color: adjustBrightness(colorFromText(chatsModel.current_chat), _bright_koef_from)
                        //     }
                        //     GradientStop {
                        //         position: 1.0
                        //         color: adjustBrightness(colorFromText(chatsModel.current_chat), _bright_koef_to)
                        //     }
                        // }

                        // layer.enabled: true
                        // layer.effect: DropShadow {
                        //     horizontalOffset: 1
                        //     verticalOffset: 0
                        //     radius: 10
                        //     samples: 32
                        //     color: "red"//Colors.default_shadow
                        // }

                        MonserratText {
                            anchors.centerIn: parent
                            font.pixelSize: parent.height / 2
                            text: userInfo.text && userInfo.text.length > 0 ? userInfo.text[0].toUpperCase() : ""
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 1
                                verticalOffset: 0
                                radius: 6
                                samples: 16
                                color: Colors.default_shadow
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log(chatsModel.current_chat, adjustBrightness(colorFromText(chatsModel.current_chat), _bright_koef_to))
                            }
                        }
                    }

                    MonserratText {
                        id: userInfo
                        anchors.left: avatar.right
                        anchors.right: chatSettingsButton.left
                        height: parent.height
                        color: Colors.text_field_style.placeholder
                        text: /*selectorChatsOrAllUsers.all_user_state ? userList.current_user : */chatsModel.current_chat
                        font.pixelSize: 14
                        leftPadding: 5
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    SquareButton {
                        id: chatSettingsButton
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        style: Colors.button_square_send_message_style
                        icon: IcoMoon.chat_settings
                        koef_icon_size: 0.66
                        height: 32
                        width: 32
                        onClicked: {
                            hideMenu()
                            var point = chatSettingsButton.mapToItem(messengerRoot, 0, 0)
                            menuChat.x = point.x - menuChat.width + width
                            menuChat.y = point.y + chatSettingsButton.height + 6
                            menuChat.visible = true
                        }
                    }
                }
            }

            ListView {
                id: chatList
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: replyBox.top
                    top: userInfoItem.bottom
                    leftMargin: 5
                    rightMargin: 5
                    bottomMargin: 0
                }

                clip: true
                spacing: 3
                model: messengerController?.chatModel
                verticalLayoutDirection: ListView.BottomToTop
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    id: chatScrollBar
                    policy: ScrollBar.AsNeeded
                    width: 3
                    rightPadding: 2
                    interactive: true
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: width / 2
                        color: Colors.messenger.scroll_bar
                        opacity: 0.8
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }

                    background: Rectangle {
                        color: "transparent"
                    }
                }
                preferredHighlightBegin: 1.0
                preferredHighlightEnd: 1.0
                highlightMoveDuration: 300
                delegate: chooser

                DelegateChooser {
                    id: chooser
                    role: "type"


                    DelegateChoice {
                        roleValue: 1

                        Item {
                            width: _delegate_chat_width
                            height: 23

                            Rectangle {
                                anchors.centerIn: parent
                                color: Colors.messenger.day_separator; radius: height / 2

                                MonserratText {
                                    anchors.centerIn: parent
                                    text: "chat created"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: Colors.messenger.day_separator_text
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: 2

                        Item {
                            width: _delegate_chat_width
                            height: 23

                            Rectangle {
                                anchors.centerIn: parent
                                color: Colors.messenger.day_separator; radius: height / 2

                                MonserratText {
                                    anchors.centerIn: parent
                                    text: "invite " + message.text
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                    color: Colors.messenger.day_separator_text
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: 3

                        Item {
                            width: _delegate_chat_width
                            height: 23

                            Rectangle {
                                anchors.centerIn: parent
                                color: Colors.messenger.day_separator; radius: height / 2

                                MonserratText {
                                    anchors.centerIn: parent
                                    text: message.text + " joined"
                                    verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
                                    color: Colors.messenger.day_separator_text
                                }
                            }
                        }
                    }

                    DelegateChoice {
                        roleValue: MessegeDelegateType.Text
                        TextMessengerDelegate {
                            id: messageDelegate
                            width: _delegate_chat_width
                            maxWidth: chatList.width * 0.7
                            minWidth: ((chatList.width * 0.3) - 20)
                            isShowDateSeparator: chatList.isShowDateSeparator(index, timestamp, type)
                            hasReplyAnswer: message.has_reply ?? false
                            replyType: message.reply_type ?? 0
                            replyMessage: message.reply_text_message ?? ""
                            parentMessageId: message.parent_message_id ?? ""
                        }
                    }

                    DelegateChoice {
                        roleValue: MessegeDelegateType.Image

                        ImageMessengerDelegate {
                            id: imageDelegate
                            width: _delegate_chat_width
                            maxWidth: chatList.width * 0.5
                            isShowDateSeparator: chatList.isShowDateSeparator(index, timestamp, type)
                            hasReplyAnswer: message.has_reply ?? false
                            replyType: message.reply_type ?? 0
                            replyMessage: message.reply_text_message ?? ""
                            parentMessageId: message.parent_message_id ?? ""
                            hasCaption: message.has_caption ?? false
                            caption: message.caption ?? ""

                        }
                    }

                    DelegateChoice {
                        roleValue: MessegeDelegateType.Gif

                        GifMessengerDelegate {
                            id: gifDelegate
                            width: _delegate_chat_width
                            maxWidth: chatList.width * 0.5
                            minWidth: ((chatList.width * 0.1) - 20)
                            isShowDateSeparator: chatList.isShowDateSeparator(index, timestamp, type)
                            hasReplyAnswer: message.has_reply ?? false
                            replyType: message.reply_type ?? 0
                            replyMessage: message.reply_text_message ?? ""
                            parentMessageId: message.parent_message_id ?? ""
                        }
                    }

                    DelegateChoice {
                        roleValue:  MessegeDelegateType.Video
                        VideoMessengerDelegate {
                            id: videoDelegate
                            width: _delegate_chat_width
                            maxWidth: chatList.width * 0.5
                            isShowDateSeparator: chatList.isShowDateSeparator(index, timestamp, type)
                            hasReplyAnswer: message.has_reply ?? false
                            replyType: message.reply_type ?? 0
                            replyMessage: message.reply_text_message ?? ""
                            parentMessageId: message.parent_message_id ?? ""
                            hasCaption: message.has_caption ?? false
                            caption: message.caption ?? ""
                        }
                    }

                    DelegateChoice {
                        roleValue: MessegeDelegateType.File
                        FileMessengerDelegate {
                            id: fileDelegate
                            width: _delegate_chat_width
                            maxWidth: 200
                            minWidth: 50
                            isShowDateSeparator: chatList.isShowDateSeparator(index, timestamp, type)
                            hasReplyAnswer: message.has_reply ?? false
                            replyType: message.reply_type ?? 0
                            replyMessage: message.reply_text_message ?? ""
                            parentMessageId: message.parent_message_id ?? ""
                            hasCaption: message.has_caption ?? false
                            caption: message.caption ?? ""
                        }
                    }
                }

                function isShowDateSeparator(index, timestamp, t) {
                    if(t === 1 || t === 2) {
                        console.log("type is not supported", t)
                        return false;
                    }

                    if(index > 0 && model.get(index -1)) {
                        var prev = model.get(index +1);
                        if(prev.type === 2)
                            return true;
                    }

                    if (index >= 0) {
                        if(index +1 === model.count)
                            return false
                        var next = model.get(index +1);
                        let dateMessageTimestamp = new Date(timestamp).toLocaleDateString()
                        let dateMessageNextTimestamp = new Date(next.timestamp).toLocaleDateString()
                        return dateMessageTimestamp !== dateMessageNextTimestamp;
                    }
                    return false
                }

                Connections {
                    target: messengerController

                    function onMoveToIndex(indexDelegate) {
                        const firstVisible = Math.floor(chatList.visibleArea.yPosition * chatList.count);
                        const lastVisible = Math.ceil((chatList.visibleArea.yPosition + chatList.visibleArea.heightRatio) * chatList.count) - 1;

                        if (indexDelegate < firstVisible || indexDelegate > lastVisible) {
                            chatList.positionViewAtIndex(indexDelegate, ListView.End)
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                visible: menuAddFile.visible
                onClicked: menuAddFile.visible = false
            }

            Rectangle {
                id: menuAddFile
                anchors.left: parent.left
                anchors.bottom: inputMessageBox.top
                width: 160
                height: 80
                radius: _radius
                visible: false
                color: Colors.messenger.menu_add_background

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        //first element menu
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        radius: _radius
                        color: Colors.messenger.menu_add_background
                        opacity: addVideoOrImageMouse.containsMouse ? 0.7 : 1.0

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                            opacity: parent.opacity
                        }

                        MouseArea {
                            id: addVideoOrImageMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                timerCheckMenuAddFileContainMouse.menuAddFileContainMouse = true
                            }

                            onExited: {
                                timerCheckMenuAddFileContainMouse.menuAddFileContainMouse = false
                            }

                            onClicked: {
                                console.log("addVideoOrImage")
                                if(!ios_platform && !android_platform) {
                                    menuAddFile.visible = false
                                    fileDialog.all_file_mode = false
                                    fileDialog.open()
                                }
                                else if(ios_platform) {
                                    console.log("addVideoOrImage for ios platform.")
                                } else if(android_platform) {
                                    console.log("addVideoOrImage for ios platform.")
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                Item {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 30

                                    IconText {
                                        anchors.centerIn: parent
                                        font.pixelSize: 18
                                        text: IcoMoon.image
                                        color: Colors.detault_text_color
                                    }
                                }

                                MonserratText {
                                    Layout.preferredHeight: parent.height
                                    Layout.fillWidth: true
                                    text: qsTr("Photo or Video")
                                    verticalAlignment: Text.AlignVCenter
                                    color: Colors.detault_text_color
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 1
                        Layout.fillWidth: true
                        color: "white"
                    }

                    Rectangle {
                        //last element menu
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        radius: _radius
                        color: Colors.messenger.menu_add_background
                        opacity: addFileMouse.containsMouse ? 0.7 : 1.0

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                            opacity: parent.opacity
                        }

                        MouseArea {
                            id: addFileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("addFileMouse")
                                menuAddFile.visible = false
                                fileDialog.all_file_mode = true
                                fileDialog.open()
                            }

                            onEntered: {
                                timerCheckMenuAddFileContainMouse.menuAddFileContainMouse = true
                            }

                            onExited: {
                                timerCheckMenuAddFileContainMouse.menuAddFileContainMouse = false
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                Item {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: 30

                                    IconText {
                                        anchors.centerIn: parent
                                        font.pixelSize: 18
                                        text: IcoMoon.attach
                                        color: Colors.detault_text_color
                                    }
                                }

                                MonserratText {
                                    Layout.preferredHeight: parent.height
                                    Layout.fillWidth: true
                                    text: qsTr("File")
                                    color: Colors.detault_text_color
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            MessageReply {
                id: replyBox
                anchors.bottom: inputMessageBox.top
                anchors.left: parent.left
                anchors.leftMargin:  menuAddFile.visible ? menuAddFile.width + 5 : 0
                anchors.right: parent.right
                radius: _radius
                visible: reply_state || edit_state
                onVisibleChanged: {
                    Qt.callLater(function() {
                        chatList.positionViewAtBeginning()
                    })
                }
            }

            Rectangle {
                id: inputMessageBox
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 3
                anchors.rightMargin: 3
                height: Math.min(80, Math.max(60, te.implicitHeight + (te.lineCount > 1 ? 2 : 0)))
                color: Colors.background
                visible: false

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: console.log(containsMouse)
                }

                ScrollView {
                    id: view
                    anchors.fill: parent
                    anchors.margins: 1
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                    ScrollBar.horizontal.interactive: false

                    TextArea {
                        id: te
                        wrapMode: TextEdit.Wrap
                        // clip: true
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        topPadding: 10
                        leftPadding: addNewFileOrImageButton.width
                        rightPadding: sendMessageButton.width + gifButton.width + 14
                        color: Colors.detault_text_color
                        font.family: Montserrat.monserrat
                        font.pixelSize: 14
                        selectByMouse: true
                        focus: true
                        enabled: !gifMenu.visible || !menu.visible || !menuChat.visible

                        onFocusChanged: {
                            console.log("focus_changed", focus)
                            messengerController?.updateChatListModel();
                        }

                        onTextChanged: {
                            timerUpdateDraft.restart()
                            messengerController?.updateCacheInput(chatsModel.current_chat_id, text)
                        }

                        Timer {
                            id: timerUpdateDraft
                            interval: 500
                            onTriggered: {
                                messengerController?.updateChatListModel();
                            }
                        }

                        Keys.onPressed: (event) => {
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                if (event.modifiers & Qt.ShiftModifier) {
                                                    te.insert(te.cursorPosition, "\n")
                                                    event.accepted = true
                                                } else {
                                                    event.accepted = true
                                                    if (text.trim().length === 0) return
                                                    if(!reply_state) {
                                                        let message = te.text.trim();
                                                        if (message.startsWith("https://media.tenor.com/") && message.endsWith(".gif")) {
                                                            messengerController?.sendGif(message);
                                                        } else {
                                                            messengerController?.sendMessage(message);
                                                        }
                                                    } else {
                                                        console.log("reply to message id:", replyBox.messageId)
                                                        messengerController?.replyMessage(message, replyBox.messageId)
                                                    }

                                                    messengerController?.updateChatListModel();
                                                    te.text = ""
                                                    Qt.callLater(function() {
                                                        chatList.positionViewAtBeginning()
                                                    })
                                                }
                                            }
                                        }

                        background: Rectangle {
                            color: Colors.text_field_style.background
                            radius: _radius
                        }
                    }
                }

                SquareButton {
                    id: addNewFileOrImageButton
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.leftMargin: 3
                    style: Colors.button_square_send_message_style
                    icon: IcoMoon.attach
                    rotation_icon: 45
                    koef_icon_size: 0.66
                    width: opacity ? visible * 44 : 18
                    height: 32
                    hoverEnabled: true
                    z: replyBox.z +1
                    onEntered: {
                        console.log("mouse_entered")
                        if(menuAddFile.visible)
                            return
                        hideMenu()
                        timerCheckMenuAddFileContainMouse.menuAddFileContainMouse = true
                        timerCheckMenuAddFileContainMouse.start()
                    }

                    Timer {
                        id: timerCheckMenuAddFileContainMouse
                        property bool menuAddFileContainMouse: false
                        interval: 500
                        onTriggered: {
                            console.log("triggered", menuAddFileContainMouse)
                            if(menuAddFileContainMouse && !addNewFileOrImageButton.containsMouse) {
                                console.log("contain maouse")
                                menuAddFileContainMouse = false
                                hideMenu()
                            }
                            if(menuAddFileContainMouse && addNewFileOrImageButton.containsMouse) {
                                menuAddFile.visible = true
                                menuAddFileContainMouse = false
                            }
                        }
                    }

                    onClicked: {
                        hideMenu()
                        menuAddFile.visible = true
                        menuAddFileContainMouse = false
                    }
                }

                SquareButton {
                    id: gifButton
                    anchors.right: sendMessageButton.left
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.rightMargin: 4
                    style: Colors.button_square_send_message_style
                    icon: IcoMoon.gif
                    koef_icon_size: 0.66
                    width: visible * 44
                    height: 32
                    z: 100

                    onClicked: {
                        gifMenu.visible = true
                    }
                }

                SquareButton {
                    id: sendMessageButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    anchors.rightMargin: 4
                    // visible: root.isMobile
                    style: Colors.button_square_send_message_style
                    icon: IcoMoon.send
                    rotation_icon: 45
                    koef_icon_size: 0.66
                    width: visible * 44
                    height: 32
                    enabled: te.text.length > 0
                    z: 100

                    onClicked: {
                        if (te.text.trim().length === 0) return
                        let message = te.text.trim();
                        if(!reply_state && !edit_state) {
                            if (message.startsWith("https://media.tenor.com/") && message.endsWith(".gif")) {
                                messengerController?.sendGif(message);
                            } else {
                                messengerController?.sendMessage(message);
                            }
                        } else if(reply_state && !edit_state) {
                            console.log("reply to message id:", replyBox.messageId)
                            messengerController?.replyMessage(message, replyBox.messageId)
                        } else if(edit_state && !reply_state) {
                            console.log("edit to message id:", replyBox.messageId)
                            messengerController?.editMessage(message, replyBox.messageId)
                        }

                        messengerController?.updateChatListModel();
                        te.text = ""
                        reply_state = false
                        Qt.callLater(function() {
                            chatList.positionViewAtBeginning()
                        })
                    }
                }
            }

            MonserratText {
                anchors.centerIn: parent
                text: qsTr("Still no messages")
                color: Colors.detault_text_color
                font.pixelSize: 16
                visible: chatList.model.count === 0 && inputMessageBox.visible
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(400, parent.width - 20)
                height: 200
                radius:  _radius *2
                visible: dropArea.containsDrag
                color: darkenColor(parent.color, 0.2)
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 1
                    verticalOffset: 0
                    radius: 6
                    samples: 16
                    color: Colors.default_shadow
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(400, parent.width - 20)
                    height: implicitHeight

                    IconText {
                        Layout.preferredWidth: 50
                        Layout.preferredHeight: 50
                        Layout.alignment: Qt.AlignHCenter
                        text: IcoMoon.import_keystore
                        color: Colors.button_square_send_message_style.color_icon
                        font.pixelSize: 40
                    }

                    MonserratText {
                        id: dndText
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.alignment: Qt.AlignHCenter
                        text: "Drag a file here to upload"
                        font.pixelSize: 20
                        elide: Text.ElideRight
                        color: Colors.detault_text_color
                    }
                }
            }
        }

        Rectangle {
            id: blurItem
            anchors.fill: parent
            visible: false

            Image {
                id: screenshotImage
                anchors.fill: parent
                visible: false
                smooth: true
            }

            FastBlur {
                id: blurEffect
                anchors.fill: parent
                source: screenshotImage
                radius: 40
                visible: screenshotImage.visible
            }

            Rectangle {
                id: dublicateMessageRect
                visible: screenshotImage.visible

                TextEdit {
                    id: messageDublicateText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    anchors.bottomMargin: 20
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    textFormat: chatsModel.type === 2 ? Text.MarkdownText : Text.PlainText
                    color: "white"
                    selectByMouse: true
                    font.family: Montserrat.monserrat
                    cursorVisible: true
                    selectionColor: Colors.messenger.selection_color
                    selectedTextColor: "white"
                    focus: false
                }

                MonserratText {
                    id: dublicateTimeText
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 5
                    font.pixelSize: 10
                    color: "white"
                    opacity: 0.7
                }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: !root.isMobile
        spacing: 0
        Item {
            id: listChatsDesktopItem
            Layout.fillHeight: true
            Layout.preferredWidth: 250
        }

        Item {
            id: messageDesktopItem
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    property alias swipeView: swipeView

    SwipeView {
        id: swipeView
        anchors.fill: parent
        visible: root.isMobile
        currentIndex: 0
        interactive: false

        onCurrentIndexChanged: {
            if (currentIndex === 0) {
                if (interactive) {
                    Qt.callLater(() => interactive = false)
                    hideMenu()
                }
            } else if (currentIndex === 1) {
                if (!interactive) {
                    Qt.callLater(() => interactive = true)
                }
            }
        }

        Item {
            id: listChatsMobileItem
        }

        Item {
            id: messageMobileItem
            visible: swipeView.currentIndex === 1
        }
    }

    RaccoonMessageBox {
        id: create_chat_message_box

        property int current_index_of_users_list: -1
        property string current_username
        property string current_user_of_users_list
        title: "Create chat"
        info_text: "Would you like to create a chat with " + current_username + "?"
        use_check_box: false
        onAgree: {
            let result = messengerController?.createChat(current_user)

            if (result) {
                userList.currentIndex = current_index_of_users_list
                userList.current_user = current_user_of_users_list

                if (root.isMobile) {
                    swipeView.incrementCurrentIndex()
                }

                notificationToolTip.message = qsTr(`Successfully created a chat with user ${current_user_of_users_list}`);
                notificationToolTip.showMessage()

                selectorChatsOrAllUsers.all_user_state = false
            } else {
                notificationToolTip.message = qsTr(`Unable to create a chat with user  ${current_user_of_users_list}`);
                notificationToolTip.showMessage()
            }

            console.log("create_chat_result:", result)
        }
    }

    RaccoonMessageBox {
        id: change_username_box
        title: "Create chat"
        info_text: "Your username is empty. Please go to settings and set a username. Would you like to go there now?"
        use_check_box: false

        onAgree: {
            root.sellected_window = MenuSelector.Settings
            settingsPage.openUsernamePage()
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        visible: menu.visible || menuChat.visible || gifMenu.visible

        Rectangle {
            anchors.fill: parent
            opacity: 0.1
        }

        onClicked: {
            hideMenu()
        }
    }

    Rectangle {
        id: gifMenu
        anchors.right: parent.right
        y: chatItem.height - inputMessageBox.height - height
        width: chatItem.width * (isMobile ? 1.0 : 0.5)
        height: chatItem.height * (isMobile ? 0.9 : 0.75)
        radius: _radius
        visible: false
        color: Colors.messenger.menu_add_background
        z: ma.z + 1

        onVisibleChanged: {
            if(visible)
                te.focus = false
            else
                te.forceActiveFocus()
        }

        Item {
            id: tenor
            property string apiKey: "AIzaSyDmXbY_-Z2w11dJlkN7wNQww5IEx2AJVf8"
            property string searchQuery: searchGifTextField.text.length > 0 ? searchGifTextField.text : "raccoon"
            property int limit: 100
            property var results: []

            function getGif() {
                let xhr = new XMLHttpRequest();
                let url = `https://tenor.googleapis.com/v2/search?q=${searchQuery}&key=${apiKey}&limit=${limit}`;

                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                        let response = JSON.parse(xhr.responseText);

                        if (response.results && response.results.length > 0) {
                            results = response.results.map(item => item.media_formats.gif.url);
                            gifView.model = results;
                        } else {
                            console.log("No results found.");
                        }
                    } else if (xhr.readyState === XMLHttpRequest.DONE) {
                        console.log("Error: ", xhr.status, xhr.statusText);
                    }
                };

                xhr.open("GET", url);
                xhr.send();
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 10

            Component.onCompleted: {
                // tenor.getGif();
            }

            Item {
                id: textFieldGifBox
                Layout.fillWidth: true
                Layout.preferredHeight: root.isMobile ? 40 : 50

                RaccoonTextField {
                    id: searchGifTextField
                    width: parent.width - 4
                    height: isMobile ? 40 : 42
                    x: 2
                    anchors.bottom: parent.bottom
                    placeholderText: "Search"
                    font.family: Montserrat.monserrat
                    font.pointSize: isMobile ? 16 : 14
                    focus: false

                    onTextChanged: {
                        timerSearch.restart()
                    }

                    Timer {
                        id: timerSearch
                        interval: 500
                        onTriggered: {
                            tenor.getGif()
                        }
                    }
                }
            }

            GridView {
                id: gifView
                Layout.fillWidth: true
                Layout.fillHeight: true

                property int spacing: 3
                property int columns: 4

                cellHeight: cellWidth * 1.3
                cellWidth: (width) / columns
                interactive: true

                model: tenor.results
                clip: true

                delegate: MouseArea {
                    width: gifView.cellWidth
                    height: gifView.cellHeight

                    Rectangle {
                        width: parent.width - gifView.spacing
                        height: parent.height - gifView.spacing
                        color: Colors.dfs_page.folder_user
                        anchors.centerIn: parent

                        AnimatedImage {
                            id: aImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            cache: true
                            source: modelData
                        }

                        BusyIndicator {
                            anchors.centerIn: parent
                            width: 50
                            height: 50
                            running: true
                            antialiasing: true
                            visible: aImage.status !== Image.Ready
                        }
                    }

                    onClicked: {
                        var reply_message_id = reply_state ? replyBox.messageId : ""
                        console.log("Selected: ", modelData, reply_message_id)
                        messengerController?.sendGif(modelData, reply_message_id)
                        messengerController?.updateChatListModel();
                        hideMenu()
                        Qt.callLater(function() {
                            chatList.positionViewAtBeginning()
                        })
                    }
                }
            }
        }
    }

    MenuMessenger {
        id: menu
    }

    Rectangle {
        id: menuChat
        property int parent_index: -1
        y: root.isMobile ? 42 : 46

        width: removeChatText.paintedWidth +45
        height: 40
        visible: false
        radius: _radius
        color: Colors.messenger.menu_add_background

        onVisibleChanged: {
            if(visible) {
                te.focus = false
            } else {
                te.forceActiveFocus()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                radius: _radius
                color: Colors.messenger.menu_add_background
                opacity: copyMouseArea.containsMouse ? 0.7 : 1.0

                MouseArea {
                    id: removeChatMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        menuChat.visible = false
                        notificationToolTip.showMessage("Soon. Chat deleted.")
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        spacing: 0

                        Item {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 30

                            IconText {
                                anchors.centerIn: parent
                                font.pixelSize: 18
                                text: IcoMoon.trash
                                color: Colors.red
                                opacity: removeChatMouse.pressed ? 0.7 : 1.0
                            }
                        }

                        MonserratText {
                            id: removeChatText
                            Layout.preferredHeight: parent.height
                            Layout.fillWidth: true
                            text: qsTr("Remove chat")
                            verticalAlignment: Text.AlignVCenter
                            color: Colors.red
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select a file"
        fileMode: FileDialog.OpenFile
        property bool all_file_mode: false
        nameFilters: all_file_mode ? ["All files (*)"] : [
                                         "Image (*.png *.jpg *.jpeg *.gif *.bmp *.webp)",
                                         "Video (*.mp4 *.avi *.mov *.mkv *.webm)"
                                     ]
        onAccepted:  {
            var files = fileDialog.selectedFiles
            var list = []

            for(let i = 0; i !== files.length; i++) {
                var cf = Qt.platform.os === "windows"
                        ? files[i].toString().replace("file:///", "")
                        : files[i].toString().replace("file://", "");
                console.log(cf)
                list.push(cf)
            }

            var fileUrl = selectedFile.toString()
            var localPath = Qt.platform.os === "windows"
                    ? fileUrl.replace("file:///", "")
                    : fileUrl.replace("file://", "");
            var fileName = localPath.split("/").pop();
            var ext = localPath.split('.').pop().toLowerCase()
            var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp"]
            var videoExts = ["mp4", "avi", "mov", "mkv", "webm"]
            var isImage = imageExts.indexOf(ext) !== -1
            var isVideo = videoExts.indexOf(ext) !== -1
            if(!all_file_mode) {
                popupAddFiles.isImage = isImage
                popupAddFiles.isVideo = isVideo
                popupAddFiles.isFile = false
            } else {
                popupAddFiles.isFile = true
                popupAddFiles.isImage = false
                popupAddFiles.isVideo = false
            }
            popupAddFiles.nameFile = fileName
            popupAddFiles.listFiles = list

            popupAddFiles.file = fileDialog.selectedFile
            popupAddFiles.open()
        }
    }

    MessageAddMediaWithCaption {
        id: popupAddFiles
    }

    Connections {
        target: messengerController

        function onMessengerAddedFile(pathToFile, selectedFile, asFile, replyMessageId, caption) {
            console.log("replyBox.messageId:", replyBox.messageId)
            if(asFile) {
                console.log("send as file", replyMessageId, pathToFile)
                messengerController?.sendFile(pathToFile, replyMessageId, caption)
            } else {
                var fileUrl = selectedFile.toString()
                var localPath = Qt.platform.os === "windows"
                        ? fileUrl.replace("file:///", "")
                        : fileUrl.replace("file://", "");
                var ext = localPath.split('.').pop().toLowerCase()
                var imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp"]
                var videoExts = ["mp4", "avi", "mov", "mkv", "webm"]
                var isImage = imageExts.indexOf(ext) !== -1
                var isVideo = videoExts.indexOf(ext) !== -1

                if (isImage) {
                    console.log("selected image file", pathToFile, localPath, replyMessageId, caption)
                    messengerController?.sendImage(pathToFile, selectedFile, replyMessageId, caption)
                } else if (isVideo) {
                    console.log("selected video file", pathToFile, selectedFile, replyMessageId)
                    messengerController?.sendVideo(pathToFile, replyMessageId, caption)
                }
            }

            if(reply_state)
                replyBox.visible = false
        }
    }

    states: [
        State {
            when: root.isMobile
            PropertyChanges { target: listItem; parent: listChatsMobileItem }
            PropertyChanges { target: chatItem; parent: messageMobileItem }
        },
        State {
            when: !root.isMobile
            PropertyChanges { target: listItem; parent: listChatsDesktopItem }
            PropertyChanges { target: chatItem; parent: messageDesktopItem }
        }
    ]
}
