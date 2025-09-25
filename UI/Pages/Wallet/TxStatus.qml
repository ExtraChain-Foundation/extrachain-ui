import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../Controls"
import "../../Fonts"
import "../../"

Rectangle {
    id: withdrawRoot
    Layout.fillWidth: true
    Layout.fillHeight: true

    anchors.fill: parent
    color: Colors.background
    border.color: Colors.border_color
    border.width: isMobile ? 0 : 1
    radius: 8

    property bool txStatus: false
    property string expError: ""

    Connections {
        target: root
        function onCurrentPageChanged() {
            loaderWithdrawal.visible = false
        }
    }

    BackButton {
        width: 174
        height: 46
        text: "Back to My wallet"
        x: isMobile ? 16 : 24
        y: isMobile ? 16 : 30
        onClickedBack: loaderWithdrawal.visible = false
    }

    ColumnLayout {
        id: cl
        anchors.centerIn: parent
        spacing: 18

        IconText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: 48
            text: txStatus ? IcoMoon.check : IcoMoon.fault_tx
            font.pixelSize: 48
            color: txStatus ? Colors.green : Colors.red
        }

        DmsansText {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 300
            horizontalAlignment: Text.AlignHCenter
            text: txStatus ? qsTr("Transaction successful!") : qsTr("Transaction failed!")
            font.pixelSize: 18
            color: Colors.def_color_text
        }
    }
}
