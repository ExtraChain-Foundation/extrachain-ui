import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"

Button {
    id: newButton
    width: 140
    height: 48
    text: "NEW"
    font.family: Montserrat.monserrat
    font.pixelSize: 16

    property QtObject style: Colors.button_blue_style
    property color text_color: style.color_text
    property real opacity_text_pressed: style.opacity_pressed
    property string _icon: IcoMoon.plus
    property int hAlighment: Text.AlignHCenter
    readonly property real _opacity: newButton.pressed ? newButton.opacity_text_pressed : 1.0

    contentItem: Item {
        id: contentText

        RowLayout {
            anchors.centerIn: parent
            spacing: 12
            IconText {
                Layout.fillHeight: true
                Layout.preferredWidth: 20
                color: newButton.text_color
                text: _icon
                font.pixelSize: 20
                verticalAlignment: Text.AlignTop
                opacity: _opacity
            }

            MonserratText {
                Layout.fillHeight: true
                Layout.fillWidth: true
                text: newButton.text
                font: newButton.font
                opacity: _opacity
                color: newButton.text_color
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        id: background
        radius: newButton.style.radius
        color: newButton.style.background
        opacity: _opacity
    }
}
