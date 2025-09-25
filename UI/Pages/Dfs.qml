import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt5Compat.GraphicalEffects
import QtCore
import QtQuick.Effects
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

RaccoonPage {
    id: dfsRoot
    anchors.fill: parent
    visible: currentPage === MenuSelector.Dfs
    meshVisible: false

    property bool isActiveMenuAdd: false
    property string currentActor: raccoonController?.mainActor || ""

    property string storageUsageInGb: dfsFileFilterModel.usedSpace
    property int maxSizeStorage: dfsDirFilterModel?.maxSpace
    property int storageUsageInPercent: 0
    property bool fileOverlayState: false
    readonly property bool hasFiles: filesView.model.count !== 0


    onVisibleChanged: {
        if(visible) {
            console.log("jump to main actor folder", raccoonController?.mainActor)
            dfsFileFilterModel?.jumpToFolder(raccoonController?.mainActor)
            searchTF.focus = false
            storageUsageInGb = dfsFileFilterModel.usedSpace
            caclPercent()
        }
    }

    Connections {
        target: dfsFileFilterModel
        function onFileAdded() {
            caclPercent()
        }
    }

    Connections {
        target: dfsFileFilterModel
        function onFileRemoved() {
            caclPercent()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            searchTF.focus = false
        }
    }

    Item {
        id: pageContent
        anchors.fill: parent

        Flickable {
            id: flickable
            anchors.topMargin: 1
            anchors.fill: parent
            contentWidth: width
            contentHeight: contentItem.childrenRect.height
            clip: true
            boundsMovement: Flickable.StopAtBounds

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - (2 * (isMobile ? 2 : 4))
                height: implicitHeight
                spacing: 10

                Rectangle {
                    id: dataInfo
                    Layout.fillWidth: true
                    Layout.preferredHeight: isMobile ? 80 : 70
                    color: Colors.background
                    radius: 14
                    border.width: 1
                    border.color: Colors.border_color
                }

                Item {
                    id: searchTFItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    visible: false//isDesktop
                }

                DmsansText {
                    id: recentFilesText
                    Layout.fillWidth: true
                    Layout.preferredHeight: paintedHeight
                    text: "Recent files"
                    color: Colors.def_color_text
                    font.pixelSize: 18
                    font.weight: 600
                    visible: hasFiles
                }

                ListView {
                    id: filesView
                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: contentHeight
                    model: appSettings.onboard_finished ? dfsFileFilterModel : 1
                    interactive: false
                    clip: true
                    spacing: isMobile ? 16 : 19
                    visible: onboarding_current_page !== Onboarding.Storage_View_Options
                    signal closeMenuFile()

                    delegate: MouseArea {
                        id: fileDelegate
                        width: ListView.view.width
                        height: 64

                        Rectangle {
                            anchors.fill: parent
                            color: filesView.currentIndex === index ? Colors.wallet.background : "transparent"
                        }

                        onClicked: {
                            filesView.currentIndex = index
                            // if(!settingsFile.visible) {
                            //     settingsFile.visible = true
                            // }
                        }

                        onPressAndHold: {
                            var point = mapToItem(dfsRoot, 0, 0);
                            blurredItem.encrypted = model.encrypted
                            blurredItem.type = model.type
                            blurredItem.name = model.name
                            blurredItem.size = model.size
                            blurredItem.index = index
                            blurredItem.fileId = model.fileId
                            blurredItem.created = model.created
                            fileOverlayState = true

                            blurredItem.pointY = point.y
                        }

                        RowLayout {
                            width: parent.width
                            height: parent.height
                            spacing: 8
                            visible: !appSettings.onboard_finished

                            Image {
                                Layout.preferredHeight: isMobile ? 42 : 48
                                Layout.preferredWidth: Layout.preferredHeight
                                Layout.alignment: Qt.AlignVCenter
                                source: "qrc:/new_design/UI/Images/new_design/lorem_text.png"
                                antialiasing: true
                            }

                            ColumnLayout {
                                Layout.preferredHeight: 48
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4
                                DmsansText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Non-Disclosure Agreement 2025"
                                    font.weight: 600
                                    color: Colors.def_color_text
                                }

                                DmsansText {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 22
                                    verticalAlignment: Text.AlignVCenter
                                    text: "2.1 MB"
                                    font.weight: 500
                                    color: Colors.dfs_page
                                }

                            }

                            DmsansText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: paintedHeight
                                Layout.preferredWidth: paintedWidth
                                text: "May 20, 14:44"
                                font.weight: 400
                                font.pixelSize: 14
                                color: Colors.dfs_page.created
                            }
                        }

                        RowLayout {
                            width: parent.width
                            height: parent.height
                            anchors.margins: 0
                            visible: appSettings.onboard_finished

                            IconText {
                                Layout.preferredHeight: 45
                                Layout.preferredWidth: 20
                                Layout.alignment: Qt.AlignVCenter
                                text: model.encrypted ? IcoMoon.lock_close : IcoMoon.file
                                font.pixelSize: 20
                                color: Colors.dfs_page.list_text

                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -10
                                    onClicked: {
                                        notificationToolTip.showMessage("🔒 File encrypted", Tooltip.Message)
                                    }
                                }
                            }

                            Rectangle {
                                id: imageContainer
                                Layout.preferredHeight: isMobile ? 42 : 48
                                Layout.preferredWidth: Layout.preferredHeight
                                Layout.alignment: Qt.AlignVCenter
                                radius: 8
                                color: "transparent"//Colors.dfs_page.image_container

                                Image {
                                    id: sourceImage
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectCrop
                                    antialiasing: true
                                    source: "qrc:/images/UI/Images/file.png"
                                    visible: isImageFile(type)
                                }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    fillMode: Image.PreserveAspectCrop
                                    antialiasing: true
                                    visible: !isImageFile(model.type)
                                    source: "qrc:/images/UI/Images/file.png"
                                    sourceSize.height: height
                                    sourceSize.width: width
                                }

                                layer.enabled: !isSoftwareRendering && isImageFile(type)
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: imageContainer.width
                                        height: imageContainer.height
                                        radius: 8
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.preferredHeight: implicitHeight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: isMobile ? 2 : 4

                                DmsansText {
                                    id: nameFiletext
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    text: model.name
                                    font.pixelSize: 14
                                    color: Colors.def_color_text
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }

                                DmsansText {
                                    id: sizeFileText
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 20
                                    text: sizeToMb(model.size)
                                    font.pixelSize: 14
                                    color: Colors.def_color_text
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: parent.height
                            }

                            DmsansText {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: paintedHeight
                                Layout.preferredWidth: paintedWidth
                                Layout.rightMargin: 4
                                text: model.created
                                font.weight: 400
                                font.pixelSize: 14
                                color: Colors.dfs_page.created
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: searchTFItem.mapToItem(dfsRoot, 0 ,0).y
        visible: !hasFiles

        ColumnLayout {
            width: implicitWidth
            height: implicitHeight
            anchors.centerIn: parent
            spacing: 14

            IconText {
                Layout.preferredWidth: 32
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignHCenter
                color: Colors.grape_gray_color
                text: IcoMoon.sad
                font.pixelSize: 32
            }

            DmsansText {
                Layout.preferredWidth: paintedWidth
                Layout.preferredHeight: 20
                color: Colors.grape_gray_color
                text: "Your storage is empty"
                font.pixelSize: 16
                font.weight: 500
            }
        }
    }

    FastBlur {
        anchors.fill: parent
        source: pageContent
        radius: 22
        visible: fileOverlayState
    }

    Item {
        id: blurredItem
        anchors.fill: parent
        visible: fileOverlayState
        property int pointY: 0
        property bool encrypted
        property string type
        property string name
        property int size
        property int index
        property string fileId
        property string created

        MouseArea {
            anchors.fill: parent
            onClicked: {
                fileOverlayState = false
            }
        }

        Rectangle {
            width: 200
            height: columnMenu.implicitHeight
            anchors.bottom: fileInfoBox.top
            anchors.bottomMargin: 8
            radius: 8
            border.color: Colors.border_color
            color: Colors.background
            anchors.horizontalCenter: parent.horizontalCenter

            ColumnLayout {
                id: columnMenu
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                width: parent.width

                ListView {
                    Layout.preferredHeight: contentHeight
                    Layout.fillWidth: true
                    model: ["Export", "Delete"]
                    clip: true
                    interactive: false
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 48
                        radius: 8
                        color: !m.pressed ? Colors.wallet.background : Colors.dfs_page.column_menu_list_unpressed

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                            visible: index === 0
                        }

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: parent.radius
                            color: parent.color
                            visible: index === 1
                        }

                        MouseArea {
                            id: m
                            anchors.fill: parent
                            DmsansText {
                                anchors.fill: parent
                                leftPadding: 14
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 16
                                font.weight: 500
                                text: modelData
                                color: index !== 1 ? Colors.def_color_text : Colors.red
                            }

                            onClicked: {
                                switch(index) {
                                case 0: {
                                    console.log("begin export")
                                    exportFolderDialog.filename = blurredItem.name
                                    exportFolderDialog.index = blurredItem.index
                                    exportFolderDialog.currentFolder = "/";
                                    exportFolderDialog.currentFolder = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];

                                    if(ios_platform) {
                                        console.log("begin export file for ios.", blurredItem.name)
                                        menuFileBox.visible = false
                                        let path = dfsFileFilterModel.exportData(blurredItem.index);
                                        if(path !== "")
                                            filePicker.exportFile(path);
                                    } else {
                                        exportFolderDialog.open();
                                        menuFileBox.visible = false
                                    }
                                }
                                break;

                                case 1: {
                                    console.log("begin remove")
                                    console.log("current actor,", currentActor)
                                    console.log("current file,", model.fileId)
                                    removeMessageBox.currentActor = currentActor
                                    removeMessageBox.fileId = blurredItem.fileId
                                    removeMessageBox.visible = true
                                }
                                break;
                                }
                                fileOverlayState = false
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: fileInfoBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            height: 64
            color: Colors.wallet.background// Colors.dfs_page.file_infobox_background
            y: parent.pointY

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: isMobile ? 2 : 4
                anchors.rightMargin: anchors.leftMargin

                IconText {
                    Layout.preferredHeight: 45
                    Layout.preferredWidth: 20
                    Layout.alignment: Qt.AlignVCenter
                    text: blurredItem.encrypted ? IcoMoon.lock_close : IcoMoon.file
                    font.pixelSize: 20
                    color: Colors.dfs_page.file_infobox_text

                    MouseArea {
                        anchors.fill: parent; anchors.margins: -10
                        onClicked: {
                            notificationToolTip.showMessage("🔒 File encrypted", Tooltip.Message)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredHeight: isMobile ? 42 : 48
                    Layout.preferredWidth: Layout.preferredHeight
                    Layout.alignment: Qt.AlignVCenter
                    radius: 8
                    color: "transparent"//Colors.dfs_page.image_container

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        source: "qrc:/images/UI/Images/file.png"
                        visible: isImageFile(blurredItem.type)
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        fillMode: Image.PreserveAspectCrop
                        antialiasing: true
                        visible: !isImageFile(model.type)
                        source: "qrc:/images/UI/Images/file.png"
                        sourceSize.height: height
                        sourceSize.width: width
                    }

                    layer.enabled: !isSoftwareRendering && isImageFile(blurredItem.type)
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: 8
                        }
                    }
                }

                ColumnLayout {
                    Layout.preferredHeight: implicitHeight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: isMobile ? 2 : 4

                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        text: blurredItem.name
                        font.pixelSize: 14
                        color: Colors.def_color_text
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    DmsansText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        text: sizeToMb(blurredItem.size)
                        font.pixelSize: 14
                        color: Colors.def_color_text
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: parent.height
                }

                DmsansText {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: paintedHeight
                    Layout.preferredWidth: paintedWidth
                    Layout.rightMargin: 4
                    text: blurredItem.created
                    font.weight: 400
                    font.pixelSize: 14
                    color: Colors.dfs_page.created
                }
            }
        }
    }

    RaccoonTextField {
        id: searchTF
        anchors.fill: parent
        parent: onboarding_current_page === Onboarding.Storage_Search ? searchTutorialItem : searchTFItem
        property bool inFolder: false
        placeholderText: "Search"
        // color: Colors.text_field_style.placeholder
        // placeholderTextColor: Colors.dfs_page.search_placeholder
        font.family: Montserrat.dmsans
        font.pointSize: 16
        focus: false
        // background: Rectangle {
        //     color: Colors.text_field_style.background
        //     radius: 16
        //     border.width: 1
        //     border.color: Colors.dfs_page.search_border_color

        //     IconText {
        //         anchors.verticalCenter: parent.verticalCenter
        //         x: 12
        //         text: IcoMoon.search
        //         color: Colors.def_color_text
        //         font.pixelSize: 18
        //     }
        // }
        // leftPadding: 38
        onTextChanged: {
            searchTimer.restart()
        }

        Timer {
            id: searchTimer
            interval: 500
            onTriggered: {
                console.log("start find files and files", searchTF.inFolder)
                let text = searchTF.text.trim()
                dfsFileFilterModel?.searchIn(text)
                dfsDirFilterModel.searchIn(text)
            }
        }
    }

    BlackRectangle {
        id: onboardingShadow
        opacity: 0.2
        visible: !appSettings.onboard_finished
    }

    Item {
        id: dataInfoTutorialItem
        anchors.horizontalCenter: parent.horizontalCenter
        y: isMobile ? 66 : 1
        width: parent.width - (2 * (isMobile ? 9 : 17))
        height: isMobile ? 80 : 70
        visible: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_Upgrade
    }

    Rectangle {
        id: dataInfoTutorial
        color: Colors.wallet.background
        anchors.fill: parent
        parent: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_Upgrade ? dataInfoTutorialItem : dataInfo
        radius: 14
        border.width: 1
        border.color: Colors.border_color

        Column {
            anchors.fill: parent
            anchors.margins: 16

            Item {
                id: dataSpaceInfo
                width: parent.width
                height: parent.height

                Text {
                    id: useStorageText
                    height: 24
                    width: parent.width
                    text: !isOnboardingState ? Colors.dfs_page.storage_calc_text(dfsFileFilterModel?.usedSpace, maxSizeStorage) :
                                               Colors.dfs_page.storage_calc_text(23.4, 100)
                    font.pixelSize: 16
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    font.family: Montserrat.dmsans
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 8
                    radius: height/2
                    color: Colors.dfs_page.storage_used_background_indicator

                    Rectangle {
                        width:  !isOnboardingState ? ((storageUsageInPercent * parent.width) /100) : ((23.4 * parent.width) /100)
                        height: parent.height
                        radius: height/2
                        gradient: Gradient{
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Colors.dfs_page.space_info_gradient_begin }
                            GradientStop { position: 1.0; color: Colors.dfs_page.space_info_gradient_end }
                        }
                    }
                }

                Rectangle {
                    width: 82
                    height: 28
                    radius: height/2
                    anchors.right: parent.right
                    anchors.verticalCenter: useStorageText.verticalCenter
                    opacity: upgradeMouse.pressed ? 0.7 : 1.0
                    enabled: !isOnboardingState
                    visible: false

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Colors.dfs_page.upgrade_button_gradient_begin }
                        GradientStop { position: 1.0; color: Colors.dfs_page.upgrade_button_gradient_end }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: Colors.background
                        radius: height/2
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            text: "Upgrade"
                            font.family: Montserrat.dmsans
                            color: Colors.def_color_text
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                        }

                        Image {
                            Layout.preferredHeight: 12
                            Layout.preferredWidth: Layout.preferredHeight
                            Layout.alignment: Qt.AlignVCenter
                            source: "qrc:/new_design/UI/Images/new_design/upgrage.svg"
                            antialiasing: true
                        }
                    }

                    MouseArea {
                        id: upgradeMouse
                        anchors.fill: parent
                        onClicked: {
                            if(isOnboardingState)
                                return
                            currentPage = MenuSelector.Wallet
                            walletPage.showSubscriptionPage()
                        }
                    }
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            spacing: 14
            visible: filesView.model.length === 0

            IconText {
                Layout.preferredWidth: 32
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignHCenter
                color: Colors.grape_gray_color
                text: IcoMoon.sad
                font.pixelSize: 32
            }

            DmsansText {
                Layout.preferredWidth: paintedWidth
                Layout.preferredHeight: 20
                color: Colors.grape_gray_color
                text: "Your storage is empty"
                font.pixelSize: 16
                font.weight: 500
            }
        }
    }

    Item {
        id: searchTutorialItem
        width: dataInfoTutorial.width
        height: searchTF.height
        anchors.horizontalCenter: parent.horizontalCenter
        y: dataInfoTutorialItem.y + dataInfoTutorialItem.height + 5
        visible: onboarding_current_page === Onboarding.Storage_Search
    }

    Rectangle {
        id: itemOnboardingFile
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 26
        height: 64
        y: filesView.y + 1
        color: Colors.dfs_page.onboarding_file
        visible: onboarding_current_page === Onboarding.Storage_View_Options

        RowLayout {
            width: parent.width
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Image {
                Layout.preferredHeight: isMobile ? 42 : 48
                Layout.preferredWidth: Layout.preferredHeight
                Layout.leftMargin: 4
                source: "qrc:/new_design/UI/Images/new_design/lorem_text.png"
                antialiasing: true
            }

            ColumnLayout {
                Layout.preferredHeight: 48
                Layout.fillWidth: true
                spacing: 4
                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    verticalAlignment: Text.AlignVCenter
                    text: "Non-Disclosure Agreement 2025"
                    font.weight: 600
                    color: Colors.def_color_text
                }

                DmsansText {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    verticalAlignment: Text.AlignVCenter
                    text: "2.1 MB"
                    font.weight: 500
                    color: Colors.dfs_page.file_size
                }

            }

            DmsansText {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: paintedHeight
                Layout.preferredWidth: paintedWidth
                Layout.rightMargin: 4
                text: "May 20, 14:44"
                font.weight: 400
                font.pixelSize: 14
                color: Colors.dfs_page.file_size
            }
        }
    }

    RowLayout {
        id: onBoarding_notification_and_settings
        anchors.top: parent.top
        anchors.topMargin: 1
        width: dataInfoTutorial.width
        height: 56 * visible
        anchors.horizontalCenter: parent.horizontalCenter
        visible: onboarding_current_page === Onboarding.Storage_Notification_and_Settings && isMobile
        z: visible ? 10000 : 0
        enabled: false

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
            }
        }
    }

    RaccoonMessageBox {
        id: removeMessageBox
        title: "ExtraChain"
        info_text: "Are you sure you want to delete this file?"
        use_check_box: false
        property string currentActor
        property string fileId

        onAgree: {
            raccoonController.removeFile(currentActor, fileId)
            dfsFileFilterModel.refresh(currentActor)
            removeMessageBox.close()
        }
    }

    Rectangle {
        id: menuFileBox
        anchors.right: parent.right
        width: 180
        height: colFileMenu.implicitHeight
        color: Colors.dfs_page.folder
        radius: 12
        visible: false

        Connections {
            target: filesView

            function onCloseMenuFile() {
                console.log("on_close_menu_file")
                if(menuFileBox.visible && index !== filesView.currentIndex)
                    menuFileBox.visible = false
            }
        }

        ColumnLayout {
            id: colFileMenu
            width: 170
            x: 5
            height: implicitHeight

            RaccoonIconButton {
                Layout.preferredWidth: 170
                Layout.preferredHeight: 40
                text: qsTr("Close")
                hAlighment: Text.AlignRight
                _icon: IcoMoon.close
                style: Colors.button_lightblue_style_old

                onClicked: {
                    menuFileBox.visible = false
                }
            }

            RaccoonIconButton {
                Layout.preferredWidth: 170
                Layout.preferredHeight: 40
                text: qsTr("Export file")
                hAlighment: Text.AlignRight
                _icon: IcoMoon.withdrawal
                style: Colors.button_lightblue_style_old
                visible: Qt.platform.os !== "android"

                onClicked: {
                    console.log("start export file")
                    exportFolderDialog.filename = model.name
                    exportFolderDialog.index = index
                    exportFolderDialog.currentFolder = "/";
                    exportFolderDialog.currentFolder = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0];

                    if(ios_platform) {
                        console.log("begin export file for ios.", model.name)
                        menuFileBox.visible = false
                        let path = dfsFileFilterModel.exportData(index);
                        if(path !== "")
                            filePicker.exportFile(path);
                    } else {
                        exportFolderDialog.open();
                        menuFileBox.visible = false
                    }
                }
            }

            RaccoonIconButton {
                Layout.preferredWidth: 170
                Layout.preferredHeight: 40
                text: qsTr("Delete file")
                hAlighment: Text.AlignRight
                _icon: IcoMoon.trash
                style: Colors.button_lightblue_style_old

                onClicked: {
                    console.log("start delete file.")
                    console.log("current actor,", currentActor)
                    console.log("current file,", model.fileId)

                    raccoonController.removeFile(currentActor, model.fileId)
                    dfsFileFilterModel.refresh(currentActor)
                    menuFileBox.visible = false
                }
            }
        }
    }

    FolderDialog {
        id: exportFolderDialog
        property string filename
        property int index
        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        onAccepted: {
            if (android_platform) {
                dfsFileFilterModel.exportFile(exportFolderDialog.index, exportFolderDialog.selectedFolder.toString())
                return
            }

            let path = Qt.resolvedUrl(exportFolderDialog.selectedFolder).toString()
            path = Qt.platform.os === "windows"
                    ? path.replace("file:///", "")
                    : path.replace("file://", "");

            if (Qt.platform.os === "windows" && /^\/[A-Za-z]:/.test(path)) {
                path = path.substring(1);
            }
            console.log("Selected folder:", path);
            console.log("Generated file name:", exportFolderDialog.filename);

            dfsFileFilterModel.exportFile(exportFolderDialog.index, path);
        }
    }

    Popup {
        id: popupfromFMOrGallery
        width: parent.width
        height: 100
        modal: true
        visible: false && root.isMobile
        property bool isImage: true
        signal openGallery()
        signal openFileDialog()

        Overlay.modal: Rectangle {
            color: Colors.background
            opacity: 0.3
        }

        enter: Transition {
            NumberAnimation {
                property: "y";
                from: popupfromFMOrGallery.parent.height
                to: popupfromFMOrGallery.parent.height - popupfromFMOrGallery.height;
                duration: 500
            }
        }
        exit: Transition {
            NumberAnimation {
                property: "y";
                from: popupfromFMOrGallery.y
                to: popupfromFMOrGallery.parent.height;
                duration: 0
            }
        }

        background: Rectangle {
            radius: 10
            color: Colors.menuPopup_old.background
        }

        onVisibleChanged: {
            if (!visible) {
                // popupfromFMOrGallery.y = previousPosition
            }
        }

        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 15

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 25
                    spacing: 20

                    IconText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: 20
                        color: Colors.menuPopup_old.text
                        text: IcoMoon.gallery
                        font.pixelSize: 25
                    }

                    MonserratText {
                        Layout.preferredHeight: parent.height
                        Layout.fillWidth: true
                        text: qsTr("Gallery")
                        horizontalAlignment:Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.menuPopup_old.text
                        font.pixelSize: 16
                        elide: Text.ElideRight

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                popupfromFMOrGallery.visible = false
                                newMediaIosDialog.openPicker()
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 25
                    enabled: popupfromFMOrGallery.isImage
                    spacing: 20

                    IconText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: 20
                        color: Colors.menuPopup_old.text
                        text: IcoMoon.file
                        font.pixelSize: 25
                    }

                    MonserratText {
                        Layout.preferredHeight: parent.height
                        Layout.fillWidth: true
                        text: qsTr("File")
                        horizontalAlignment:Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        color: Colors.menuPopup_old.text
                        font.pixelSize: 16
                        elide: Text.ElideRight
                        enabled: popupfromFMOrGallery.isImage
                        opacity: popupfromFMOrGallery.isImage ? 1.0 : 0.6

                        MouseArea {
                            anchors.fill: parent
                            enabled: popupfromFMOrGallery.isImage
                            onClicked: {
                                popupfromFMOrGallery.visible = false
                                filePicker.pickAnyFile()
                            }
                        }
                    }
                }
            }

            Connections {
                target: filePicker

                function onSelectedFile(file_path) {
                    console.log("filePath: ", file_path)
                    let cleanPath = file_path.startsWith("file://") ? file_path.substring(7) : file_path;
                    var list = [];
                    list.push(cleanPath)
                    uiController.addFiles(list, 0, false)
                }
            }
        }
    }

    ImagePicker {
        id: newMediaIosDialog

        onFile: importKeystore(f.toString())
        onImagePathChanged: {
            console.log('imagePath', imagePath)
            var list = [];
            list.push(imagePath)
            console.log("list append: ", list)
            uiController.addFiles(list, 0, false)
        }
    }

    BlueButton {
        id: newButton
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: isMobile ? 16 : 0
        width: 41
        height: 41
        enabled: true && !isOnboardingState
        visible: !fileOverlayState
        isAddButton: true

        property bool dfsLoaded

        onClicked: {

            // if (!dfsRoot.checkSubscription()) {
            //     return
            // }

            // if (!root.cheatMode && !uiController.subscribeActive) {
            //     notificationToolTip.showMessage("Currently unavailable, please try again later", Tooltip.Message)
            //     return
            // }

            // if (!root.cheatMode && !uiController.subscribed) {
            //     notificationToolTip.showMessage(qsTr("Please subscribe to gain access to the VPN service"), Tooltip.Message)
            //     currentPage = MenuSelector.Wallet
            //     walletPage.showSubscriptionPage()
            //     return
            // }

            console.log("pressed new file or folder in. show menu.")
            if(ios_platform) {
                popupfromFMOrGallery.open()
            } else {
                tempFileDialog.open()
            }
        }
    }

    Column {
        id: onborading_column
        anchors.top: onboarding_current_page === Onboarding.Storage_Space ? dataInfoTutorialItem.bottom :
                                                                            onboarding_current_page === Onboarding.Storage_Upgrade ? dataInfoTutorialItem.verticalCenter :
                                                                                                                                     onboarding_current_page === Onboarding.Storage_Search ? searchTutorialItem.bottom :
                                                                                                                                                                                             onboarding_current_page === Onboarding.Storage_View_Options ? itemOnboardingFile.bottom :
                                                                                                                                                                                                                                                           onboarding_current_page === Onboarding.Storage_Notification_and_Settings && isMobile ? dataInfoTutorialItem.top
                                                                                                                                                                                                                                                                                                                                                : undefined
        anchors.topMargin: onboarding_current_page === Onboarding.Storage_Upgrade && isDesktop ? 5
                                                                                               : onboarding_current_page === Onboarding.Storage_Notification_and_Settings && isMobile  ? -7 : 0
        anchors.bottom: onboarding_current_page === Onboarding.Storage_Notification_and_Settings ? newButton.top : undefined
        anchors.bottomMargin: 5
        width: 340
        height: implicitHeight
        spacing: 4
        x: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_Search ? (parent.width - width) /2 :
                                                                                                                           onboarding_current_page === Onboarding.Storage_Upgrade ? (isMobile ?  (dfsRoot.width -16 - width) : (dfsRoot.width - 20 - width)) :
                                                                                                                                                                                    (onboarding_current_page === Onboarding.Storage_Notification_and_Settings && !isMobile) ? 100
                                                                                                                                                                                                                                                                            : (parent.width - width) /2


        z: visible ? 10000 : 0

        Repeater {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_Upgrade || onboarding_current_page === Onboarding.Storage_Search
                     || onboarding_current_page === Onboarding.Storage_View_Options || (isMobile && onboarding_current_page === Onboarding.Storage_Notification_and_Settings)
            model: visible ? 7 : 0
            Rectangle {
                x: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_View_Options ? 170
                                                                                                                                       :  onboarding_current_page === Onboarding.Storage_Upgrade ? onborading_column.width - 57 :
                                                                                                                                                                                                   (isMobile && onboarding_current_page === Onboarding.Storage_Notification_and_Settings) ? onborading_column.width - 25
                                                                                                                                                                                                                                                                                          : 170
                width: 2
                height: 4
                color: Colors.dfs_page.onboarding_box_color
            }
        }

        Item {
            id: tutorialInformationBoxForAllPlatform
            visible: onboarding_current_page === Onboarding.Storage_Space || onboarding_current_page === Onboarding.Storage_Upgrade || onboarding_current_page === Onboarding.Storage_Search
                     || onboarding_current_page === Onboarding.Storage_View_Options ||  onboarding_current_page === Onboarding.Storage_Notification_and_Settings
            width: 340
            height: onboardingInformPanel._implicitHeightInfo + 32
        }
    }

    OnboardingInformPanel {
        id: onboardingInformPanel
        anchors.fill: parent
        parent: tutorialInformationBoxForAllPlatform
    }

    Item {
        id: line_between_settings_and_onboard_rectangle
        anchors.left: parent.left
        anchors.leftMargin: -15
        anchors.right: onborading_column.left
        y: parent.height - 120
        height: 1
        visible: isDesktop && (onboarding_current_page === Onboarding.Storage_Notification_and_Settings)

        Row {
            spacing: 4
            anchors.fill: parent

            Repeater {
                model: line_between_settings_and_onboard_rectangle.width / 5
                Rectangle {
                    width: 4
                    height: 2
                    color: Colors.dfs_page.onboarding_box_color
                }
            }
        }
    }

    FileDialog {
        id: tempFileDialog

        onAccepted: {
            var list = [];
            var files = tempFileDialog.selectedFiles
            for(let i = 0; i !== files.length; i++) {
                list[i] = files[i].toString().replace(filePrefix, '')
            }

            if (checkDuplicate(list)) {
                return
            }

            uiController.addFiles(list, 0, false)
            newButton.dfsLoaded = true
        }
    }

    DropArea {
        id: fileDropArea
        anchors.fill: parent

        Rectangle {
            id: dropIndicator
            anchors.fill: parent
            anchors.margins: -8
            color: Colors.dfs_page.drop_indicator_background
            opacity: 0.2
            radius: 12
            visible: parent.containsDrag
        }

        MonserratText {
            anchors.centerIn: parent
            text: qsTr("Drop file here to upload")
            font.pixelSize: 24
            color: Colors.dfs_page.drop_indicator_text
            visible: parent.containsDrag
        }

        onEntered: function(drag) {
            if (drag.hasUrls) {
                drag.accepted = true;
            } else {
                drag.accepted = false;
            }
        }

        onDropped: function(drop) {
            if (drop.hasUrls) {
                if (!dfsRoot.checkSubscription()) {
                    return
                }

                var fileList = [];
                for (var i = 0; i < drop.urls.length; i++) {
                    var filePath = drop.urls[i].toString().replace(filePrefix, '')
                    fileList.push(filePath);
                }

                if (checkDuplicate(fileList)) {
                    return
                }

                if (fileList.length > 0) {
                    uiController.addFiles(fileList, 0, false);
                    newButton.dfsLoaded = true;
                }
            }
        }
    }

    function caclPercent() {
        storageUsageInGb = dfsFileFilterModel.usedSpace
        if(storageUsageInGb >= maxSizeStorage) {
            console.log("caclPercent_100")
            storageUsageInPercent =  100;
        }

        if(storageUsageInGb > 0) {
            var res = (storageUsageInGb/maxSizeStorage) * 100;
            console.log("caclPercent_100", res, storageUsageInGb, maxSizeStorage)
            storageUsageInPercent = res
        }
    }

    function isImageFile(type) {
        return (type === 'jpg' || type === 'png' || type === 'gif' || type === 'webp')
    }

    function checkSubscription() {
        if (uiController?.networkSockets === 0) {
            notificationToolTip.message = "Waiting for network connection"
            notificationToolTip.showMessage()
            return false
        }

        if (!root.cheatMode && !uiController.subscribeActive) {
            notificationToolTip.showMessage(qsTr("Currently unavailable, please try again later"))
            return false
        }

        if (!root.cheatMode && !uiController.subscribed) {
            notificationToolTip.showMessage(qsTr("Please subscribe to gain access to the VPN service"))
            currentPage = MenuSelector.Wallet
            walletPage.showSubscriptionPage()
            return false
        }

        return true
    }

    function checkDuplicate(fileList) {
        for(let j = 0; j !== dfsFileFilterModel.count; j++) {
            const el = dfsFileFilterModel.get(j)
            console.log(JSON.stringify(el))
            for(let k = 0; k !== fileList.length; k++) {
                const fileName = uiController.fileName(fileList[k])
                console.log(fileName)
                if (el.name === fileName) {
                    notificationToolTip.showMessage("Duplicate name")
                    return true
                }
            }
        }

        return false
    }

    function sizeToMb(s) {
        const mb = 1024 * 1024;
        const gb = 1024 * mb;
        const count_symbols = 4

        if (s >= gb) {
            return (s / gb).toFixed(count_symbols) + " GB";
        } else if (s >= mb) {
            return (s / mb).toFixed(count_symbols) + " MB";
        } else {
            return (s / mb).toFixed(count_symbols) + " MB";
        }
    }
}
