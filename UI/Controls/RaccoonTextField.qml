import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Controls"
import "../Fonts"

Item {
    property string coin_name
    property bool useButtonMax: false
    property bool useCopyButton: false
    property bool useSearchIcon: false
    property alias text: confirmPasswordTF.text
    property string placeholderText
    property alias font: confirmPasswordTF.font
    property alias echoMode: confirmPasswordTF.echoMode
    property alias validator: confirmPasswordTF.validator
    property alias enableTextField: confirmPasswordTF.enabled
    property alias rigthPadding: confirmPasswordTF.rightPadding
    property alias focusTf: confirmPasswordTF.focus
    property int error_border_width: 0
    property int _radius: 8

    readonly property QtObject style: Colors.raccoonTextFieldDefaultStyle

    signal max()
    signal copy()

    TextField {
        id: confirmPasswordTF
        anchors.fill: parent
        leftPadding: leftIcon.visible ? 40 : 12
        rightPadding: 12
        placeholderTextColor: Colors.text_field_style.placeholder
        color: Colors.text_field_style.placeholder
        font.family: Montserrat.dmsans
        font.pointSize: 16
        selectByMouse: true
        background: Rectangle {
            id: bg
            color: Colors.text_field_style.background
            radius: _radius
            border.color: Colors.text_field_style.border_color
            border.width: 1
        }
    }

    IconText {
        id: leftIcon
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        color: Colors.raccoonTextFieldDefaultStyle.max_button
        text: IcoMoon.search
        font.pixelSize: 20
        verticalAlignment: Text.AlignTop
        visible: useSearchIcon
    }

    Text {
        anchors.right: maxButton.left
        anchors.rightMargin: 8
        height: parent.height
        width: contentWidth
        text: coin_name
        font.family: Montserrat.dmsans
        visible: coin_name.length > 0
        color: Colors.raccoonTextFieldDefaultStyle.name_coin
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 16
    }

    Text {
        id: maxButton
        anchors.right: parent.right
        anchors.rightMargin: 12
        height: parent.height
        width: contentWidth
        font.family: Montserrat.dmsans
        text: qsTr("Max")
        visible: useButtonMax
        color: Colors.raccoonTextFieldDefaultStyle.max_button
        verticalAlignment: Text.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("pressed max.")
                max()
            }
        }
    }

    IconText {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        color: Colors.raccoonTextFieldDefaultStyle.max_button
        text: IcoMoon.copy
        font.pixelSize: 20
        verticalAlignment: Text.AlignTop
        visible: useCopyButton
        opacity: mouseCopy.pressed ? 0.6 : 1.0

        MouseArea {
            id: mouseCopy
            anchors.fill: parent
            onClicked: {
                console.log("pressed copy.")
                copy()
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.top
        anchors.left: parent.left
        anchors.leftMargin: 16
        height: 16
        width: placeholder.paintedWidth + 8
        color: "transparent"
        visible: placeholderText.length > 0

        Rectangle {
            y: parent.height/2
            width: parent.width
            height: parent.height/2
            color: bg.color
        }

        DmsansText {
            id: placeholder
            text: placeholderText
            font.pixelSize: 12
            color: Colors.grape_gray_color
            leftPadding: 4
        }
    }
}
