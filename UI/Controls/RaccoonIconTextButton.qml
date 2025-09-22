import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Fonts"

RowLayout {
    Layout.preferredWidth: implicitWidth
    signal clicked()
    property int pixel_size: 22
    required property string text
    required property string icon

    IconText {
        Layout.preferredHeight: 22
        Layout.preferredWidth: 22
        text: parent.icon
        color: Colors.red
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 22
    }
    
    DmsansText {
        Layout.preferredWidth: paintedWidth + 20
        Layout.preferredHeight: 64
        text: parent.text
        font.pixelSize: 16
        color: Colors.red
        verticalAlignment: Text.AlignVCenter
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("pressed `"+text+"`")
            parent.clicked()
        }
    }
}
