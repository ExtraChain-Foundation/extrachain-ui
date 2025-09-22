import QtQuick
import QtQuick.Controls.Material
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

Rectangle {
    width: 120
    height: 40
    property string text: "Select"
    property int pixelSize: 16
    property bool filled: false
    property alias _label: label
    readonly property bool isRounded: width === height
    property bool isAddButton: false

    signal clicked()

    radius: filled || isAddButton ? height/2 : 0
    color: filled ?  Colors.blue_button.filled_color : "transparent"
    opacity: enabled || isOnboardingState ? 1.0 : 0.7

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: parent.clicked()

        Image {
            visible: !filled
            anchors.fill: parent
            source: !isRounded && !isAddButton ? "qrc:/new_design/UI/Images/new_design/BlueButton.png"
                                               : "qrc:/new_design/UI/Images/new_design/add_rounded.png"
            opacity: mouse.pressed ? 0.7 : 1.0
            antialiasing: true
        }

        Rectangle {
            anchors.fill: parent
            visible: isAddButton && !Colors.isDarkTheme
            radius: height /2

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#f7f7f9" }
                GradientStop { position: 1.0; color: "#f2f2f2" }

            }

            IconText {
                anchors.centerIn: parent
                text: IcoMoon.plus
                color: Colors.grape_gray_color
            }
        }
    }

    DmsansText {
        id: label
        anchors.centerIn: parent
        width: parent.width - 10
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: parent.text
        color: parent.enabled ? filled ? Colors.blue_button.filled_text_color : Colors.mining_text_color : Colors.blue_button.disabled_text_color
        font.pixelSize: parent.pixelSize
        opacity: mouse.pressed && !isOnboardingState ? 0.7 : 1.0
        visible: !isAddButton
        elide: Text.ElideRight
    }
}
