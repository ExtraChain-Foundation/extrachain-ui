import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import ExtraChain 1.0

import "../../UI/Controls"
import "../../UI/Fonts"

ComboBox {
    id: selectCoinTF
    property string currentIcon
    property string currentCoin
    property string placeholderText

    delegate: ItemDelegate {
        width: selectCoinTF.width
        height: selectCoinTF.height

        contentItem: Item {
            Image {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                height: selectCoinTF.height * 0.5
                width: height
                source: model.icon
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: label.width + 12
                rightPadding: selectCoinTF.indicator.width + selectCoinTF.spacing
                text: coin
                font: selectCoinTF.font
                color: Colors.raccoonComboBoxDefaultStyle.selected_text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }
        highlighted: selectCoinTF.highlightedIndex === index
    }

    indicator: Item {
        x: selectCoinTF.width - width - selectCoinTF.rightPadding
        y: selectCoinTF.topPadding + (selectCoinTF.availableHeight - height) / 2
        width: 12
        height: 8

        IconText {
            anchors.centerIn: parent
            text: IcoMoon.down
            color: Colors.raccoonComboBoxDefaultStyle.selected_text
        }
    }

    contentItem: Item {
        Image {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 15
            height: selectCoinTF.height * 0.5
            width: height
            source: selectCoinTF.currentIcon
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: label.width + 27
            rightPadding: selectCoinTF.indicator.width + selectCoinTF.spacing
            text: selectCoinTF.currentCoin
            font: selectCoinTF.font
            color: Colors.raccoonComboBoxDefaultStyle.selected_text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    background: Rectangle {
        height: isMobile ? 58 : 44
        width: selectCoinTF.width
        radius: 8
        color: Colors.raccoonComboBoxDefaultStyle.background
        border.color: Colors.raccoonComboBoxDefaultStyle.border
        border.width: 1

        Rectangle {
            color: Colors.background
            anchors.verticalCenter: parent.top
            anchors.left: parent.left
            anchors.leftMargin: 16
            height: 16
            width: placeholder.paintedWidth + 8
            visible: placeholderText.length > 0
            DmsansText {
                id: placeholder
                text: placeholderText
                font.pixelSize: 12
                color: Colors.grape_gray_color
                leftPadding: 4
            }
        }
    }

    popup: Popup {
        y: selectCoinTF.height - 1
        width: selectCoinTF.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: selectCoinTF.popup.visible ? selectCoinTF.delegateModel : null
            currentIndex: selectCoinTF.highlightedIndex

            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            radius: 12
            color: Colors.raccoonComboBoxDefaultStyle.background
        }
    }
}
