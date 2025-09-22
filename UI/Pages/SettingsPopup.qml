import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore as QtCore
import ExtraChain 1.0

import "../Controls"
import "../Pages"
import "../Fonts"

Popup {
    id: settingsPopup
    
    y: !isMobile ? parent.height - height -14 : 0
    x: !isMobile ? parent.width - width -14 : 0
    height: isMobile ? parent.height : (parent.height * 0.8)
    visible: root.sellected_window === MenuSelector.Settings && !isMobile
    width: isMobile ? parent.width : Math.max(472, 320)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    Overlay.modal: BlackRectangle {
        opacity: 0.9
    }
    
    background: Rectangle {
        radius: 8
        gradient: Gradient {
            GradientStop { color: Colors.settings_page.gradient_begin; position: 0.0 }
            GradientStop { color: Colors.settings_page.gradient_end; position: 1.0 }
        }
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: isMobile ? 0 : 1
            color: Colors.settings_page.background
            radius: parent.radius
        }
    }
    
    contentItem: Item {
        Settings {
            anchors.fill: parent
            visible: !isMobile
        }

    }
}
