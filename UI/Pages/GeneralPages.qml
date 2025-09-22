import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Pages"
import "../Fonts"
import "."
import "../"

Item {
    anchors.fill: parent
    // anchors.topMargin: android_platform ? statusHeight : 0
    // anchors.bottomMargin: android_platform ? navigationHeight : 0

    property alias subscription_page: subscription
    property alias menu_selector: menu

    BlackRectangle {
        id: onboardingShadow
        visible: !appSettings.onboard_finished
    }

    RowLayout {
        id: menuRow
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20
        visible: !isMobile

        MenuSelector {
            id: menu
        }

        Item {
            id: mainItemRow
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

    }

    Wallet { id: walletPage; parent: mainItemRow }

    Dfs {  id: dfsPage; parent: mainItemRow }

    // Messenger { id: messengerPage; parent: mainItemRow }

    ColumnLayout {
        id: menuColumn
        anchors.fill: parent
        visible: isMobile

        Item {
            id: mainItemCol
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        MenuSelector {
            id: menuCl
        }
    }

    Settings { id: settingsPage; parent: mainItemCol; visible: (root.sellected_window === MenuSelector.Settings && isMobile ) }

    Notification { id: notificationPage; parent: mainItemCol; visible: (root.sellected_window === MenuSelector.Notification && isMobile ) }

    Subscription {
        id: subscription
        anchors.fill: parent
        anchors.leftMargin: isMobile ? 0 : menu.width + 16
        visible: false
    }

    states: [
        State {
            name: "mobile_state"
            when: isMobile
            // PropertyChanges { target: menuRow; visible: false }
            PropertyChanges { target: menuColumn; visible: true }
            PropertyChanges { target: vpnPage; parent: mainItemCol }
            PropertyChanges { target: walletPage; parent: mainItemCol }
            PropertyChanges { target: locationsPage; parent: mainItemCol }
            PropertyChanges { target: dfsPage; parent: mainItemCol }
            // PropertyChanges { target: settingsPage; parent: mainItemCol }
            // PropertyChanges { target: notificationPage; parent: mainItemCol }
        },
        State {
            name: "desktop_state"
            when: !isMobile
            // PropertyChanges { target: menuRow; visible: true }
            PropertyChanges { target: menuColumn; visible: false }
            PropertyChanges { target: vpnPage; parent: mainItemRow }
            PropertyChanges { target: walletPage; parent: mainItemRow }
            PropertyChanges { target: locationsPage; parent: mainItemRow }
            PropertyChanges { target: dfsPage; parent: mainItemRow }
            // PropertyChanges { target: settingsPage; parent: nullptr }
            // PropertyChanges { target: notificationPage; parent: undefined }
        }
    ]

    SettingsPopup {
        id: settingsPopup
    }

    NotificationPopup {
        id: notificationPopup
    }

    Window {
        id: exportDialog
        width: 450
        height: clDialog.implicitHeight + 60
        title: title()
        modality: Qt.ApplicationModal
        visible: false
        flags: Qt.Dialog
        color: Colors.background
        onVisibleChanged: {
            if(visible)
                update()
        }

        property int type
        property bool is_new_version
        function title() {
            switch(type) {
            case 0: return "Export as File";
            case 1: return "Export as Phrase";
            case 2: return "Export as Hex";
            }
        }

        function update() {
            clDialog.reset()
            const phrases = uiController.getPhrase()
            if(exportDialog.type === 1) {
                clDialog._phrasesModel = phrases
            }

            if(exportDialog.type === 2) {
                var fullPhrase = ""
                for (let i = 0; i < phrases.length; ++i) {
                    fullPhrase += phrases[i] + ' '
                }
                clDialog._hex = uiController.importedHex(fullPhrase)
            }
        }

        Item {
            id: exportDesktop
            anchors.horizontalCenter: parent.horizontalCenter
            height: implicitHeight
            width: 390
            y: 30
        }
    }

    Rectangle {
        id: exportMobileDialog
        anchors.fill: parent
        visible: false
        color: Colors.background

        onVisibleChanged: {
            if(visible)
                exportDialog.update()
        }

        Item {
            id: exportMobilItem
            anchors.fill: parent
            anchors.margins: 20
        }
    }

    ExportColumn {
        id: clDialog
        parent: isMobile ? exportMobilItem : exportDesktop
    }

    ImagePreview {
        id: photoPreviewer
    }

    ExportPage {
        id: exportPage
        anchors.fill: parent
        Component.onCompleted: {
            if(appSettings.showExportPage)
                showExportPage()
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: editWalletPopup.visible || settingsPopup.visible || notificationPopup.visible
        onClicked: {
            editWalletPopup.visible = false
            settingsPopup.visible = false
            notificationPopup.visible = false
        }
    }

    WalletEditMobileMenu {
        id: editWalletPopup
        visible: false
        width: parent.width
    }

}
