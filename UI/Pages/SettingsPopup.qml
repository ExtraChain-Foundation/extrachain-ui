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
    
    y: isDesktop ? parent.height - height -14 : 0
    x: isDesktop ? parent.width - width -14 : 0
    height: isMobile ? parent.height : (parent.height * 0.8)
    visible: currentPage === MenuSelector.Settings && isDesktop
    width: isMobile ? parent.width : Math.max(472, 320)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    Overlay.modal: BlackRectangle {
        opacity: 0.9
    }
    
    background: Rectangle {
        radius: 8
        gradient: Gradient {
            GradientStop { color: Colors.popup.gradient_begin; position: 0.0 }
            GradientStop { color: Colors.popup.gradient_end; position: 1.0 }
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
            visible: isDesktop
        }

    }
}
