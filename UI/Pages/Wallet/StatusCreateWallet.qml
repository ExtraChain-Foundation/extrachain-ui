import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"
import "../../"

RaccoonPage {
    id: statusCreateRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    anchors.fill: parent

    signal closeStatusCreateWallet()

    Connections {
        target: root
        function onSellected_windowChanged() {
            loaderWithdrawal.visible = false
        }
    }

    MouseArea { anchors.fill: parent }

    BackButton {
        visible: false
        onClickedBack: {
            statusCreateRoot.visible = false
            showExportPage()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: cl.width + 28
        height: cl.height + 44
        radius: 8
        color: Colors.background
        border.width: 1
        border.color: Colors.border_color
    }

    ColumnLayout {
        id: cl
        anchors.centerIn: parent
        spacing: 0

        IconText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
            text: IcoMoon.check
            font.pixelSize: 24
            color: Colors.status_create_wallet.check
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: 1
        }

        DmsansText {
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: paintedWidth
            text: qsTr("New wallet created successfully")
            font.pixelSize: 16
            color: Colors.createWalletPage.title_text
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: 1
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 1
            Layout.preferredWidth: 360
            color: Colors.createWalletPage.separator
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: 1
        }

        DmsansText {
            Layout.preferredHeight: 25
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 360
            text: qsTr("Protect your assets via moving key\nfiles to remote secured place!")
            font.pixelSize: 14
            visible: false
            color: Colors.createWalletPage.title_text
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 30
            Layout.preferredWidth: 1
            visible: false
        }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 16
            Layout.preferredWidth: gotoWalletRow.implicitWidth

            RowLayout {
                id: gotoWalletRow

                DmsansText {
                    Layout.preferredHeight: 16
                    Layout.alignment: Qt.AlignLeft
                    Layout.preferredWidth: paintedWidth
                    text: qsTr("Continue")
                    font.pixelSize: 14
                    color: Colors.status_create_wallet.text
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    opacity: mouse.pressed ? 0.7 : 1.0
                }

                IconText {
                    Layout.preferredHeight: 16
                    Layout.preferredWidth: 16
                    font.pixelSize: 16
                    text: IcoMoon.down
                    rotation: 270
                    color: Colors.status_create_wallet.text
                    opacity: mouse.pressed ? 0.7 : 1.0
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                onClicked: {
                    console.log("Pressed go to wallet")
                    statusCreateRoot.visible = false

                    if (!isNewProfile) {
                        showExportPage()
                    }
                }
            }
        }
    }
}
