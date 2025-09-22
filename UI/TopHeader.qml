import QtQuick
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import ExtraChain 1.0
import "./Controls"

Rectangle {
    id: topHeader
    anchors.horizontalCenter: parent.horizontalCenter

    width: root.width - (!isMobile ? 24 : 0)
    height: !isMobile ? 50 : (ios_platform ? 100 : 75)
    radius: !isMobile ? height / 4 : 0
    clip: true
    color: Colors.background
    y: !isMobile ? 8 : 0
    
    Image {
        id: headerImage
        source: !isMobile  ? "qrc:/images/UI/Images/Header.svg" :
                            "qrc:/images/UI/Images/mobile_top_header.svg"
        width: parent.width
        height: parent.height
        fillMode: topHeader.width < 770 ? Image.Stretch : Image.PreserveAspectCrop

        layer.enabled: !isMobile && !isSoftwareRendering
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: headerImage.width
                height: headerImage.height
                radius: topHeader.radius
            }
        }

        Item {
            id: itemDesktopItemLogo
            width: 125
            height: 20
            x: 14
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            id: itemIosMobile
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 25
            width: 125
            height: 20
            x: 14
        }

        Image {
            id: logoImg
            parent: itemDesktopItemLogo
            anchors.fill: parent
            source: "qrc:/images/UI/Images/raccoon_text_and_icon_logo.svg"
            antialiasing: true
        }

        states: [
            State {
                when: ios_platform
                PropertyChanges {
                    target: logoImg; parent: itemIosMobile
                }
            },
            State {
                when: !ios_platform
                PropertyChanges {
                    target: logoImg; parent: itemDesktopItemLogo
                }
            }
        ]

        DevActivator {
            anchors.fill: parent
        }
    }
    
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 15
        y: parent.height /2 - 8

        Rectangle {
            anchors.right: networkStatusRect.left
            anchors.rightMargin: 10
            width: actor.paintedWidth + 20
            height: 30
            radius: 10
            visible: false // UiSettings.visible_indicator_connection
            color: Colors.top_header

            MonserratText {
                id: actor
                anchors.centerIn: parent
                color: 'black';
                text: raccoonController?.mainActor || ""
                font.pixelSize: root.isMobile ? 12 : 14
                font.bold: true
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                visible: networkStatusRect.visible
            }
        }

        Rectangle {
            id: networkStatusRect
            width: 20; height: 20; y: 5; x: 5
            anchors.right: parent.right
            anchors.rightMargin: 5; opacity: 0.5
            property bool status; radius: 10
            color: uiController?.networkStatus ? 'green' : 'red'
            visible: UiSettings.visible_indicator_connection
        }

        MonserratText {
            anchors.centerIn: networkStatusRect
            color: 'white'; text:  uiController?.networkStatus ? uiController?.networkSockets : "0"; font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            visible: networkStatusRect.visible
        }
    }

    Rectangle {
        width: parent.width
        height: 36
        radius: 16
        anchors.verticalCenter: parent.bottom
        visible: isMobile
        color: Colors.background
    }
}
