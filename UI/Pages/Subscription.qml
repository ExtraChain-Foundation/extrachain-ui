import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../Fonts"
import "../Controls"
import "../"

Item {
    id: subscriptionPage
    width: parent.width
    height: parent.height

    Rectangle {
        anchors.fill: parent
        color: Colors.background
        visible: currentPage === MenuSelector.Settings || currentPage === MenuSelector.Wallet
    }

    onVisibleChanged: {
        if (visible) {
            uiController?.loadSubscription()
        }
    }

    MouseArea { anchors.fill: parent }

    // Calculate responsive sizes based on width
    property real responsiveScale: Math.min(1, width / 1000)
    property real cardWidth: isMobile ? Math.max(280, (width - 100) / 3 - 20) : 300
    property bool compactMode: width < 800
    property bool selectedAnnualPlan: false


    ListModel {
        id: planModel

        ListElement {
            name: "Trial"
            price: "<span style='font-size:24px'>FREE/</span><span style='font-size:16px'>7 days</span>"
            features: "• 15 GB File Storage"
            available: true

        }

        ListElement {
            name: "Basic"
            price: "<span style='font-size:24px'>500 ROCC/</span><span style='font-size:16px'>month</span>"
            features: "• 15 GB File Storage"
            available: true
        }

        ListElement {
            name: "High Security"
            price: "<span style='font-size:24px'>10K ROCC/</span><span style='font-size:16px'>month</span>"
            features: "• All Basic features\n• Wandering flow feature\n• 100 GB File Storage"
            available: false
        }

        ListElement {
            name: "Data Fortress"
            price: "<span style='font-size:24px'>50K ROCC/</span><span style='font-size:16px'>month</span>"
            features: "• All High Security features\n• Traffic Priority\n• 1 TB File Storage"
            available: false
        }
    }

    Rectangle {
        id: mySwitch
        parent: isMobile ? mobileMySwitchItem : desktoMySwitchItem
        anchors.fill: parent
        color: Colors.subscription.switch_background
        radius: height/2

        RowLayout {
            anchors.fill: parent

            MouseArea {
                Layout.fillHeight: true
                Layout.fillWidth: true
                enabled: false
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: selectedAnnualPlan ? Colors.subscription.selected_annual_plan : Colors.subscription.unselected_annual_plan
                    radius: height/2
                    DmsansText {
                        anchors.centerIn: parent
                        font.pixelSize: 12
                        color: selectedAnnualPlan ? Colors.subscription.selected_annual_plan_text : Colors.subscription.unselected_annual_plan_text
                        text: "Annual"
                    }
                }
                onClicked: {
                    // if(!selectedAnnualPlan)
                    //     selectedAnnualPlan = true
                    notificationToolTip.showMessage("This plan is coming soon.")
                }
            }

            MouseArea {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: !selectedAnnualPlan ? Colors.subscription.monthly_background : Colors.subscription.monthly_background_unselected
                    radius: height/2

                    DmsansText {
                        anchors.centerIn: parent
                        font.pixelSize: 12
                        color: !selectedAnnualPlan ? Colors.subscription.monthly_text : Colors.subscription.monthly_text_unselected
                        text: "Monthly"
                    }
                }

                onClicked: {
                    if(selectedAnnualPlan)
                        selectedAnnualPlan = false
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: isMobile ? 10 : 18
        anchors.rightMargin: isMobile ? 10 : 0
        spacing: 28
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            visible: isMobile

            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 157
                Layout.alignment: Qt.AlignVCenter
                antialiasing: true
                source: Colors.logo_and_text
            }

            Item {
                Layout.preferredHeight: 40
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 48
                Layout.preferredWidth: 104
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.horizontalCenter
                    height: parent.height

                    Rectangle {
                        height: parent.height
                        width: height
                        radius: height/2
                        color: Colors.mobile_notification_settings_box

                        IconText {
                            anchors.centerIn: parent
                            text: IcoMoon.bell
                            color: Colors.mobile_notification_settings_text
                            font.pixelSize: 22
                            opacity: parent.pressed ? 0.8 : 1.0
                        }
                    }



                    onClicked: {
                        console.log("show notifications")
                        notificationToolTip.showMessage("This feature is coming soon.")
                    }
                }

                MouseArea {
                    anchors.left: parent.horizontalCenter
                    anchors.right: parent.right
                    height: parent.height

                    Rectangle {
                        height: parent.height
                        width: height
                        radius: height/2
                        color: Colors.mobile_notification_settings_box

                        IconText {
                            anchors.centerIn: parent
                            text: IcoMoon.settings
                            color: Colors.mobile_notification_settings_text
                            font.pixelSize: 22
                            opacity: parent.pressed ? 0.8 : 1.0
                        }
                    }

                    onClicked: {
                        console.log("show notifications")
                        currentPage = MenuSelector.Settings
                    }
                }
            }
        }

        RowLayout {
            id: rowTitle
            Layout.preferredHeight: 32
            Layout.maximumHeight: 32
            Layout.fillWidth: true
            Layout.rightMargin: 20

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 32
                SquareButton {
                    anchors.fill: parent
                    icon: IcoMoon.down
                    rotation_icon: 90
                    onClicked: subscriptionPage.visible = false
                }
            }

            DmsansText {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: isMobile ? Qt.AlignVCenter | Qt.AlignHCenter : Qt.AlignVCenter
                text: "Choose your pricing"
                color: Colors.def_color_text
                font.pixelSize: isMobile ? 24 : 18
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: isMobile ? Text.AlignHCenter : Text.AlignLeft
            }

            Item {
                id: desktoMySwitchItem
                Layout.preferredHeight: 32
                Layout.preferredWidth: 145
                Layout.alignment: Qt.AlignVCenter
                visible: isDesktop
            }
        }

        Item {
            id: mobileMySwitchItem
            Layout.preferredWidth: 145
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignHCenter
            visible: isMobile
        }

        Item {
            Layout.fillHeight: true
            Layout.fillWidth: true
            property int selectedIndex: 0

            ListView {
                id: planListView
                anchors.fill: parent
                orientation: root.isMobile ? ListView.Vertical : ListView.Horizontal
                spacing: compactMode ? 10 : 20
                model: planModel
                interactive: true//root.isMobile
                focus: true
                clip: true
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: 300
                highlightFollowsCurrentItem: true
                currentIndex: parent.selectedIndex
                onCurrentIndexChanged: {
                    parent.selectedIndex = currentIndex
                }

                delegate: Rectangle {
                    id: planCard
                    width: root.isMobile ? planListView.width : cardWidth
                    height: isDesktop ? ListView.view.height : compactMode ? 380 : 400
                    radius: 14
                    gradient: Gradient {
                        GradientStop { color: !available || index === 0 ? Colors.grape_gray_color : Colors.subscription.plan_card_gradient_begin; position: 0.0 }
                        GradientStop { color: !available || index === 0 ? Colors.grape_gray_color : Colors.subscription.plan_card_gradient_end; position: 1.0 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: parent.radius-1
                        color: !available || index === 0 ? Colors.subscription.plan_card_unavailable_background : Colors.subscription.plan_card_available_background
                    }

                    Rectangle {
                        width: parent.width - 2
                        y: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 22
                        color: !available || index === 0 ? Colors.subscription.plan_card_title_unavailable : Colors.subscription.plan_card_title_available
                        radius: parent.radius
                        Rectangle {
                            width: parent.width
                            anchors.bottom: parent.bottom
                            height: parent.radius
                            color: parent.color
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 22
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { color: !available || index === 0 ? Colors.grape_gray_color : Colors.subscription.plan_card_title_available; position: 0.0 }
                            GradientStop { color: "transparent"; position: 1.0 }
                        }

                        Rectangle {
                            id: titleBox
                            width: parent.width - 2
                            y: 1
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 22
                            color: !available || index === 0 ? Colors.subscription.title_box_unavailable : Colors.subscription.title_box_available
                            radius: parent.radius
                            Rectangle {
                                width: parent.width
                                anchors.bottom: parent.bottom
                                height: parent.radius
                                color: parent.color
                            }
                        }

                        DmsansText {
                            anchors.centerIn: parent
                            text: index === 0 ? (uiController.subscribed ? "SUBSCRIBED" : (isTrialActive ? `LEFT ${trialTimeRemaining.toUpperCase()}` : "ENDED")) : (available ? "LIMITED TIME" : "COMING SOON")
                            font.pixelSize: 12
                            color: available && index > 0 ? Colors.subscription.title_color_available : Colors.subscription.title_color_unavailable
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.topMargin: titleBox.height + 6
                        anchors.bottomMargin: lr_margin + 4
                        readonly property int lr_margin: isMobile ? 14 : 20
                        anchors.leftMargin: lr_margin
                        anchors.rightMargin: lr_margin
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: isMobile ? 80 : 72

                            DmsansText {
                                width: parent.width
                                height: 24
                                color: Colors.def_color_text
                                text: name
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                            }

                            DmsansText {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 24
                                color: Colors.def_color_text
                                textFormat: Text.RichText
                                text: price
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 24

                                function typeSubscription(type) {
                                    switch(type) {
                                    case 0: return "7 days"
                                    default: return "month"
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: Colors.grape_gray_color
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            interactive: false
                            clip: true
                            spacing: 10
                            model: getModel(index)
                            delegate: Item {
                                width: ListView.view.width
                                height: 16

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    AnimatedImage {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        antialiasing: true
                                        source: "qrc:/new_design/UI/Images/new_design/subscription_check.svg"
                                    }

                                    DmsansText {
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        color: Colors.subscription.text
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                    }
                                }
                            }

                            function getModel(index) {
                                switch(index) {
                                case 0: return ["All Basic features", "Wandering flow feature", "100 GB File Storage"]
                                case 1: return ["All High Security features", "Traffic Priority", "1 TB File Storage"]
                                }
                            }
                        }

                        ColumnLayout {
                            id: clError
                            Layout.fillWidth: true
                            Layout.preferredHeight: 25
                            spacing: 1
                            visible: false

                            DmsansText {
                                id: errorText
                                Layout.fillWidth: true
                                Layout.preferredHeight: 12
                                text: "Not enough 200 ROCCs to buy"
                                color: Colors.red
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }

                            DmsansText {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 12
                                text: "(your balance is " + walletUIController?.estimatedBalance + " ROCC)"
                                color: Colors.subscription.text
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 10
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            color: available && index !== 0 ? Colors.subscription.title_color_available : Qt.transparent
                            border.color: Colors.grape_gray_color
                            border.width: available ? 0 : 1
                            radius: height / 2

                            DmsansText {
                                anchors.centerIn: parent
                                text: {
                                    if (index === 0) {
                                        return isTrialActive && !uiController.subscribed ? qsTr("Activated") : qsTr("Unavailable")
                                    }

                                    if (available) {
                                        return !uiController?.subscribed ? qsTr("Subscribe") : qsTr("Activated") + '!'
                                    } else {
                                        return qsTr("Unavailable")
                                    }
                                }
                                color: available && index !== 0 ? Colors.subscription.activated_text : Colors.subscription.unavailable_text
                                font.pixelSize: 18
                            }

                            MouseArea {
                                id: mSubscribe
                                anchors.fill: parent
                                hoverEnabled: true

                                onHoveredChanged: {
                                    if (Number(walletUIController?.estimatedBalance) < (UiSettings.debugMode ? 1.5 : 500)) {
                                        errorText.text = "Not enough 500 ROCCs"
                                        clError.visible = index === 1
                                    }
                                }

                                onClicked: {
                                    console.log("pressed subscribe")

                                    if (!uiController.subscribeActive) {
                                        notificationToolTip.showMessage(qsTr("Currently unavailable, please try again later"))
                                        return
                                    }

                                    const atLeast = (UiSettings.debugMode ? 0.12 : 500)
                                    if (Number(walletUIController?.estimatedBalance) < atLeast) {
                                        notificationToolTip.message = qsTr(`At least ${atLeast} ROCC required for subscription`)
                                        notificationToolTip.showMessage()
                                        return
                                    }
                                    uiController.addSubscription(1, true)
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: bb
            Layout.preferredHeight: parent.height * 0.15
            Layout.fillWidth: true
            visible: isDesktop

            RowLayout {
                anchors.centerIn: parent
                width: implicitWidth
                height: 48
                spacing: 14

                Rectangle {
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: Layout.preferredHeight
                    visible: planListView.contentWidth > bb.width
                    radius: height/2
                    color: Colors.subscription.placeholder_icon
                    opacity: ml.pressed ? 0.7 : 1.0

                    IconText {
                        anchors.centerIn: parent
                        font.pixelSize: 20
                        text: IcoMoon.back
                        color: Colors.subscription.back_color
                        opacity: ml.pressed ? 0.7 : 1.0
                    }

                    MouseArea{
                        id: ml
                        anchors.fill: parent
                        onClicked: {
                            console.log(`Pressed left`)
                            var anim = Qt.createQmlObject('import QtQuick 2.0; NumberAnimation { \
                                        target: planListView; property: "contentX"; to: 0; duration: 3000; easing.type: Easing.InOutQuad \
                                    }', planListView);
                            anim.start();
                        }
                    }
                }


                Rectangle {
                    Layout.preferredHeight: 48
                    Layout.preferredWidth: Layout.preferredHeight
                    radius: height/2
                    color: Colors.subscription.placeholder_icon
                    opacity: mr.pressed ? 0.7 : 1.0
                    visible: planListView.contentWidth > bb.width


                    IconText {
                        anchors.centerIn: parent
                        font.pixelSize: 20
                        text: IcoMoon.back
                        rotation: 180
                        color: Colors.subscription.back_color
                        opacity: mr.pressed ? 0.7 : 1.0
                    }

                    MouseArea{
                        id: mr
                        anchors.fill: parent
                        onClicked: {
                            console.log(`Pressed right`)
                            var anim = Qt.createQmlObject('import QtQuick 2.0; NumberAnimation { \
                                        target: planListView; property: "contentX"; to: planListView.contentWidth - width + 50; duration: 3000; easing.type: Easing.InOutQuad \
                                    }', planListView);
                            anim.start();
                        }
                    }
                }
            }
        }
    }
}
