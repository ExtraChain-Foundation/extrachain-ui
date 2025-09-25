import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0
import "Controls"
import "Fonts"

Item {
    id: syncLoaderItem
    Layout.fillWidth: true
    width: parent.width
    height: 60
    // Layout.preferredHeight: walletUIController.syncing ? 60 : 0
    visible: opacity === 0 ? false : true // walletUIController?.syncing || false
    opacity: 1 // walletUIController?.syncing ? 1 : 0

    onVisibleChanged: {
        if (!visible) {
            txtDownloading.resetText()
            alwaysShowSection = false
            txtSections.resetText()
        }
    }

    property bool alwaysShowSection

    Rectangle {
        anchors.fill: parent
        radius: 15
        color: Colors.mining_background
        border.width: 1
        border.color: Colors.border_color
    }

    Connections {
        target: raccoonController

        function dagSyncFinish() {
            txtDownloading.text = qsTr("Finishing AcyclicChain...")
        }

        function onDagSearchControlStarted(sectionId) {
            txtDownloading.text = qsTr("Checking the integrity of AcyclicChain...")
            alwaysShowSection = true
        }

        function onDagSearchControlEnded() {
            txtDownloading.resetText()
            alwaysShowSection = false
        }

        function onDagControlStarted() {
            txtDownloading.text = qsTr("Generating controls for AcyclicChain...")
            alwaysShowSection = true
        }

        function onDagControlEnded() {
            txtDownloading.resetText()
            alwaysShowSection = false
        }

        function onActorsStarted() {
            txtDownloading.text = qsTr("Downloading actors...")
            alwaysShowSection = true
            txtSections.text = ""
        }

        function onActorsEnded() {
            txtDownloading.resetText()
            alwaysShowSection = false
            txtSections.resetText()
        }

        function onActorsProgress(current, to) {
            if (current >= to) {
                txtSections.text = qsTr("Finishing...")
                return
            }

            txtSections.text = "(%1 / %2 ".arg(current).arg(to) + qsTr("actors") + ")"
        }
    }

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: !walletUIController?.syncing ? 500 : 400
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on opacity {
        OpacityAnimator { duration: 40 }
    }

    RowLayout {
        anchors.fill: parent

        Item {
            Layout.preferredHeight: syncLoaderItem.height
            Layout.preferredWidth: syncLoaderItem.height

            BusyIndicator {
                anchors.centerIn: parent
                // visible: walletUIController?.syncing || false
                running: syncLoaderItem.visible
                width: 46
                height: 46
                antialiasing: true
            }
        }

        Item {
            id: progressInfoPanel
            Layout.preferredHeight: syncLoaderItem.height
            Layout.fillWidth: true
            property bool isFinal: Number(walletUIController?.syncTo) <= Number(walletUIController?.progress)

            ColumnLayout {
                anchors.fill: parent

                MonserratText {
                    id: txtDownloading
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: alwaysShowSection || !progressInfoPanel.isFinal? Text.AlignBottom :
                                                                   Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    color: Colors.loaderBlochain.text

                    function resetText() {
                        txtDownloading.text = Qt.binding(function() { return walletUIController?.syncing ? (progressInfoPanel.isFinal ? qsTr("Preparing AcyclicChain...") : qsTr("Downloading AcyclicChain..."))
                                                                                                         : (uiController?.networkStatus ? qsTr("Receiving data from the network...") : qsTr("Waiting for connection...")) })

                    }

                    Component.onCompleted: resetText()
                }

                MonserratText {
                    id: txtSections
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignTop; horizontalAlignment: Text.AlignLeft
                    color: Colors.loaderBlochain.text
                    visible: alwaysShowSection || !progressInfoPanel.isFinal

                    function resetText() {
                        text = Qt.binding(function() { return uiController.isBlockchainLight() ? "(light)" : "(%1 / %2 ".arg(formatNumber(walletUIController?.progress)).arg(formatNumber(walletUIController?.syncTo)) + qsTr("sections") + ")" })

                    }

                    Component.onCompleted: resetText()
                }
            }
        }
    }

    function formatNumber(str) {
        if (str.length < 6) return str

        let result = ''
        let counter = 0

        for (let i = str.length - 1; i >= 0; i--) {
            result = str[i] + result
            counter++
            if (counter % 3 === 0 && i !== 0) {
                result = " " + result
            }
        }

        return result
    }
}
