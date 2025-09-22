import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Fonts"

CheckBox {
    id: control
    checked: true
    text: ""
    indicator: Item {}

    property color unchecked: Colors.checkBox.unchecked

    contentItem:  Item {
        height: control.height
        width: control.width
        anchors.verticalCenter: parent.verticalCenter

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            height: control.height
            width: control.width
            spacing: 8

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: 22
                Layout.alignment: Qt.AlignVCenter
                width: 22
                height: 22
                radius: 4
                color: control.checked ? Colors.checkBox.checked : unchecked
                border.color: Colors.checkBox.border
                border.width: 1

                IconText {
                    anchors.centerIn: parent
                    font.pixelSize: 14
                    text: IcoMoon.checkmark
                    color: Colors.checkBox.text
                    visible: control.checked
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: control.checked = !control.checked
                }
            }

            DmsansText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: control.text
                font.pixelSize: 14
                color: Colors.def_color_text
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    onClicked: control.checked = !control.checked
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: control.checked = !control.checked
    }
}
