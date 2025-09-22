import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ExtraChain 1.0

import "../Controls"

Dialog {
    id: messageBox
    anchors.centerIn: parent
    width: root.isMobile ? root.width - 20 : Math.min(loginPage.width -20, 480)
    height: clDialog.implicitHeight + 150
    modal: true

    property string info_text: ""
    property bool use_check_box: true
    property string check_box_text: ""
    property bool confirmed: confirmationChackBox.checked

    property string additional_question_text: ""
    readonly property bool status_additional_question: additional_question_text.length === 0
                                                       ? false : allowAutoLoginCheckBox.checked
    property alias agree_text: agreeTextBtn.text
    property bool use_required_login_and_password: false
    readonly property string entered_login: login.text.trim()
    readonly property string entered_password: password.text.trim()

    function clearLogin() {
        login.text = ""
        password.text = ""
    }


    signal agree()
    signal cancel()

    Overlay.modal: BlackRectangle{}

    header: Item {
        width: parent.width
        height: 40

        DmsansText {
            text: title
            color: Colors.def_color_text
            font.pixelSize: 18
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            font.bold: true
        }
    }

    contentItem: ColumnLayout {
        id: clDialog
        width: messageBox.width
        height: label.paintedHeight + 30
        spacing: 10
        
        Text {
            id: label
            Layout.preferredHeight: paintedHeight + 10
            Layout.preferredWidth: clDialog.width
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            text: info_text
            font.family: Montserrat.dmsans
            color: Colors.def_color_text
            font.pixelSize: 14
            wrapMode: Text.Wrap
        }
        
        RaccoonCheckBox {
            id: confirmationChackBox
            Layout.preferredHeight: visible *30
            Layout.fillWidth: true
            text: check_box_text
            visible: use_check_box
            checked: false
        }

        Item {
            Layout.preferredHeight: visible *10
            Layout.fillWidth: true
            visible: additional_question_text.length > 0
        }

        RaccoonCheckBox {
            id: allowAutoLoginCheckBox
            Layout.preferredHeight: visible *22
            Layout.fillWidth: true
            text: additional_question_text
            visible: additional_question_text.length > 0
            checked: false
        }

        RaccoonTextField {
            id: login
            Layout.preferredHeight: visible *40
            Layout.fillWidth: true
            placeholderText: "Login"
            visible: use_required_login_and_password
        }
        RaccoonTextField {
            id: password
            Layout.preferredHeight: visible *40
            Layout.fillWidth: true
            placeholderText: "Password"
            visible: use_required_login_and_password
            echoMode: TextInput.Password
        }

    }
    
    background: Rectangle {
        color: Colors.message_box.background
        radius: 10
    }
    
    footer: Item {
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 10
        height: 50
        
        Rectangle {
            width: parent.width
            height: 1
        }
        
        Rectangle {
            height: parent.height
            width: 1
            anchors.centerIn: parent
        }
        
        MouseArea {
            width: parent.width/2
            height: parent.height
            enabled: use_check_box ? confirmationChackBox.checked : true
            
            Text {
                id: agreeTextBtn
                anchors.centerIn: parent
                font.pixelSize: 14
                color: Colors.def_color_text
                font.family: Montserrat.dmsans
                text: "OK"
                opacity: parent.enabled ? 1.0 : 0.7
            }
            
            onClicked: {
                console.log("Clicked `OK`")
                agree()
                accept()
                messageBox.close()
            }
        }
        
        MouseArea {
            width: parent.width/2
            height: parent.height
            x: width
            
            Text {
                anchors.centerIn: parent
                font.pixelSize: 14
                color: Colors.def_color_text
                font.family: Montserrat.dmsans
                text: "Cancel"
            }
            
            onClicked: {
                console.log("Clicked `Cancel`")
                cancel()
                messageBox.close()
            }
        }
    }
}
