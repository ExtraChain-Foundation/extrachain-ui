import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import ExtraChain 1.0

import "../Controls"
import "../"

RaccoonPage {
    id: updater
    anchors.fill: parent
    color: Colors.background
    visible: false

    property string url: isPlayMarket ? "https://play.google.com/store/apps/details?id=com.raccoonline." + isMessenger ? "vpnapp" : "messenger" : "https://raccoonline.com/#download"
    property string version

    MouseArea { anchors.fill: parent }

    Image {
        anchors.horizontalCenter: parent.horizontalCenter; y: 150
        height: 58; width: 86
        source: "qrc:/images/UI/Images/raccoonline.png"
        antialiasing: true
    }

    MonserratText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: updateNewVersionBtn.top
        anchors.bottomMargin: 20
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: "Update required" + (version ? `<br>to version <b>${version}</b>` : "")
        font.pixelSize: 16
        color: Colors.def_color_text
        width: paintedWidth
        height: paintedHeight
    }

    BlueButton {
        id: updateNewVersionBtn
        anchors.centerIn: parent
        width: 170; height: 60
        text: "Update App"
        filled: true

        onClicked: {
            enabled = false

            if (android_platform) {
                enabled = true
                Qt.openUrlExternally(updater.url)
                return
            }

            if (Qt.platform.os === "windows" || Qt.platform.os === "linux") {
                text = "Downloading..."
                progressBar.visible = true
            }

            const canUpdate = uiController.downloadUpdate()
            if (!canUpdate) {
                text = "Error"
            }
        }
    }

    ProgressBar {
        id: progressBar
        anchors.top: updateNewVersionBtn.bottom; anchors.topMargin: 60
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.4
        visible: false
    }

    Timer {
        interval: 2000
        running: !isPlayMarket
        triggeredOnStart: true

        onTriggered: {
            if (isPlayMarket || Qt.platform.os === "ios") {
                stop()
                return
            }

            if (uiController === null) {
                repeat = true
                return
            }

            const canUpdate = uiController.checkUpdate()
            console.log("[Version] Can update:", canUpdate?.length > 0)

            if (canUpdate) {
                running = false
                updater.version = canUpdate
                updater.visible = true
            } else {
                interval = 3600000
                repeat = true
                running = true
            }
        }
    }

    DeepIndigoButton {
        anchors.top: updateNewVersionBtn.bottom
        anchors.topMargin: 100
        anchors.horizontalCenter: parent.horizontalCenter
        width: updateNewVersionBtn.width; height: updateNewVersionBtn.height
        visible: UiSettings.debugMode
        text: "Close"
        onClicked: {
            updater.visible = false
            updateNewVersionBtn.enabled = true
        }
    }

    Connections {
        target: uiController

        function onUpdaterDownloadProgress(bytesReceived, bytesTotal) {
            progressBar.value = bytesReceived
            progressBar.to = bytesTotal
        }

        function onUpdaterDownloadFinished(success) {
            updateNewVersionBtn.text = "Update app"

            if (!success) {
                updateNewVersionBtn.enabled = true
                Qt.openUrlExternally(updater.url)
                Qt.quit()
                return
            }

            uiController.installUpdate()
        }
    }
}
