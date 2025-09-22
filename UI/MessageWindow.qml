import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtCore as QtCore
import ExtraChain 1.0

import "./Controls"
import "./Fonts"

Window {
    id: wnd
    readonly property int calculatedWidth: rl.implicitWidth + 20
    readonly property int calculatedHeight: 140

    width: calculatedWidth
    height: calculatedHeight

    minimumWidth: calculatedWidth
    maximumWidth: calculatedWidth

    minimumHeight: calculatedHeight
    maximumHeight: calculatedHeight

    visible: true
    color: Colors.background
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint


    Component.onCompleted: {
        wnd.x = (Screen.width - (wnd.width/2)) / 2
        wnd.y = (Screen.height - (wnd.height/2)) / 2
        console.log("isDarkMode", appSettings.isDarkMode)
        Colors.isDarkMode = appSettings.isDarkMode
    }

    QtCore.Settings {
        id: appSettings
        property bool isDarkMode: true
    }

    RowLayout {
        id: rl
        anchors.centerIn: parent
        spacing: 10
        height: parent.height - 20

        Image {
            Layout.preferredHeight: parent.height
            Layout.preferredWidth: height
            source: "qrc:/images/UI/Images/raccoon_logo.png"
            antialiasing: true
            layer.enabled: !isSoftwareRendering
            layer.effect: DropShadow {
                horizontalOffset: 1
                verticalOffset: 0
                radius: 10
                samples: 32
                color: Colors.default_shadow
            }
        }

        ColumnLayout {
            Layout.preferredHeight: parent.height
            Layout.fillWidth: true

            DmsansText {
                Layout.preferredHeight: paintedHeight
                Layout.fillWidth: true
                text: "ExtraChain is already running."
                color: Colors.message_window_text
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18
                font.weight: 600
            }

            DmsansText {
                Layout.preferredHeight: paintedHeight
                Layout.fillWidth: true
                text: "Only one instance of the application is allowed at a time."
                font.weight: 400
                color: Colors.detault_text_color
                font.pixelSize: 12
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            BlueButton {
                Layout.preferredHeight: 35
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignHCenter
                filled: true
                text: "OK"
                _label.font.weight: 600
                onClicked: {
                    raccoonController.kill()
                }
            }
        }
    }
}
