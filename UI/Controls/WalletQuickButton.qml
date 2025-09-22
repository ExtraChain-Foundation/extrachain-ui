import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

Rectangle {
    id: walletQuickButtonControl
    color: "transparent"
    border.color: Colors.grape_gray_color
    border.width: 1
    radius: 8
    property alias _icon: icon.text
    property int pxSize: 18
    property string underText: "All wallets"

    signal click()
    
    ColumnLayout {
        id: clQb
        width: implicitWidth
        height: implicitHeight
        anchors.centerIn: parent
        spacing: 4
        
        IconText {
            id: icon
            Layout.preferredHeight: 20
            Layout.preferredWidth: Layout.preferredHeight
            Layout.alignment: Qt.AlignHCenter
            color: Colors.def_color_text
            font.pixelSize: pxSize
            text: IcoMoon.wallet
            opacity: maWalletQuickButton.pressed ? 0.7 : 1.0
        }
        
        DmsansText {
            Layout.preferredWidth: paintedWidth
            Layout.preferredHeight: paintedHeight
            Layout.alignment: Qt.AlignHCenter
            color: Colors.def_color_text
            text: underText
            opacity: maWalletQuickButton.pressed ? 0.7 : 1.0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }
    }
    
    MouseArea {
        id: maWalletQuickButton
        anchors.fill: parent
        onClicked: {
            click()
        }
    }
}
