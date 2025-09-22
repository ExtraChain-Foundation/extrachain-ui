import QtQuick
import QtQuick.Controls.Material
import ExtraChain 1.0

import "."

Item {
    height: 50
    width: 50 + textButton.paintedWidth
    property alias text: textButton.text

    signal clickedBack

    SquareButton {
        id: backToWallet
        width: 50
        height: width

        style: Colors.wallet_withdraw_page.button_back_style
        size: parent.width
        icon: IcoMoon.down
        koef_icon_size: 1.0
        rotation: 90
        text: ""

        onClicked: {
            clickedBack()
        }
    }

    DmsansText {
        id: textButton
        anchors.verticalCenter: backToWallet.verticalCenter
        anchors.left: backToWallet.right
        text: qsTr("Back to my wallet")
        color: backToWallet.style.pressed_color_icon
        font.pixelSize: 16
        font.bold: true

        MouseArea {
            anchors.fill: parent
            onClicked: {
                clickedBack()
            }
        }
    }
}
