import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects
import ExtraChain 1.0

import "Controls"
import "Fonts"

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 56
    color: Colors.mining_background
    border.width: 1
    border.color: Colors.border_color
    radius: 8
    property bool miningActive: uiController?.networkStatus

    Connections {
        target: raccoonController

        function onDagControlStarted() {
            informText.text = qsTr("Generating controls for AcyclicChain...")
        }

        function onDagControlEnded() {
            // informText.text = Qt.binding(function() { return Number(walletUIController?.estimatedBalance).toFixed(3) == "NaN" ? "~" : Utils.mask(Number(walletUIController?.estimatedBalance).toFixed(3), securityState) });
        informText.text = Qt.binding(function() { return Utils.mask(!uiController?.networkStatus ? qsTr("Connecting to network...") : (qsTr("Mining ") + (miningActive ? qsTr("active") : qsTr("inactive"))), securityState) });
        }
    }
    
    Image {
        width: 51
        height: 1
        x: 66
        source: "qrc:/new_design/UI/Images/new_design/effect_for_box.png"
        visible: miningActive && !syncBlockchainLoader.opacity

        SequentialAnimation on x {
            loops: Animation.Infinite
            ParallelAnimation{
                PropertyAnimation {
                    from: parent.width - bottomEffectImage.width - 40
                    to: 40
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
            }
            
            ParallelAnimation {
                PropertyAnimation {
                    from: 40
                    to: parent.width - bottomEffectImage.width - 40
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    
    Image{
        id: bottomEffectImage
        width: 51
        height: 1
        y: parent.height - 1
        source: "qrc:/new_design/UI/Images/new_design/effect_for_box.png"
        rotation: 180
        visible: miningActive && !syncBlockchainLoader.opacity
        
        SequentialAnimation on x {
            loops: Animation.Infinite

            ParallelAnimation {
                PropertyAnimation {
                    from: 40
                    to: parent.width - bottomEffectImage.width - 40
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
            }
            
            ParallelAnimation {
                PropertyAnimation {
                    from: parent.width - bottomEffectImage.width - 40
                    to: 40
                    duration: 2000
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        
        Image {
            Layout.preferredHeight: 24
            Layout.preferredWidth: 24
            Layout.alignment: Qt.AlignVCenter
            antialiasing: true
            source: "qrc:/new_design/UI/Images/new_design/mining.svg"
        }
        
        DmsansText {
            id: informText
            Layout.preferredHeight: 24
            Layout.fillWidth: true
            text: !uiController?.networkStatus ? qsTr("Connecting to network...") : (qsTr("Mining ") + (miningActive ? qsTr("active") : qsTr("inactive")))
            font.pixelSize: 12
            color: miningActive ? Colors.mining_text_color : Colors.inactive_mining_text_color
            verticalAlignment: Text.AlignVCenter
        }
        
        DmsansText {
            Layout.preferredHeight: 24
            Layout.preferredWidth: paintedWidth
            text: Number(walletUIController?.estimatedBalance).toFixed(3) == "NaN" ? "~" : Utils.mask(Number(walletUIController?.estimatedBalance).toFixed(3), securityState)
            font.pixelSize: 12
            color: Colors.mining_text_color
            verticalAlignment: Text.AlignVCenter
            rightPadding: 4
        }
        
        Text {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            font.family: IcoMoon.iconmoon
            text: IcoMoon.raccoon
            font.pixelSize: 16
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            color: Colors.raccoon_icon
            visible: Colors.isDarkTheme
        }

        Image {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/images/UI/Images/raccoonline.png"
            visible: !Colors.isDarkTheme
        }

        MouseArea {
            Layout.fillHeight: true
            Layout.preferredWidth: 20
            Layout.alignment: Qt.AlignVCenter
            onPressed: etUtils.vibrate()
            enabled: !isOnboardingState
            onClicked: securityState = !securityState

            Text {
                width: 20
                height: 20
                anchors.centerIn: parent
                font.family: IcoMoon.iconmoon
                text: !securityState ? IcoMoon.visability : IcoMoon.lock_close
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: Colors.raccoon_icon
            }
        }
    }

    SyncBlockchainLoader {
        id: syncBlockchainLoader
        anchors.fill: parent
        opacity: walletUIController?.estimatedBalance === '~' || walletUIController?.syncing ? 1 : 0
    }
}
