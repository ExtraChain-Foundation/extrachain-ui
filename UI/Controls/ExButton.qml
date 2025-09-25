import QtQuick
import QtQuick.Controls.Material
import QtQuick.Window
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"

Button {
    id: control
    width: contentText.paintedWidth + 50
    text: "Cancel"
    font.family: Montserrat.monserrat
    font.pixelSize: 16

    property QtObject style: Colors.button_blue_style
    property color text_color: style.color_text
    property real opacity_text_pressed: style.opacity_pressed
    property int hAlighment: Text.AlignHCenter
    property int border_width: 0
    property color border_color: contentText.color
    property alias _radius: background.radius
    property alias _opacity: contentText.opacity
    property alias bgColor: background.color

    contentItem: Text {
        id: contentText
        text: control.text
        font.family: control.font
        font.pixelSize: 14
        opacity: control.pressed || !control.enabled ? parent.opacity_text_pressed : 1.0
        color: parent.text_color
        horizontalAlignment: parent.hAlighment
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        id: background
        radius: parent.style.radius
        opacity: control.pressed || !control.enabled ? parent.opacity_text_pressed : 1.0
        color: parent.style.background
        border.color: border_color
        border.width: border_width
    }
}
