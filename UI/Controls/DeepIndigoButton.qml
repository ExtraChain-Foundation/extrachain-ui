import QtQuick
import QtQuick.Controls.Material
import ExtraChain 1.0

import "../Controls"
import "../Fonts"
import "../"

MouseArea {
    width: 120
    height: 40
    property string text

    Rectangle {
        id: background
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colors.deep_indigo_button.begin_gradient_color }
            GradientStop { position: 1.0; color: Colors.deep_indigo_button.end_gradient_color }
        }

        opacity: isOnboardingState ? 1.0 : (parent.pressed || !parent.enabled) ? 0.7 : 1.0
    }
    
    DmsansText {
        anchors.centerIn: parent
        width: parent.width - 10
        height: parent.height
        text: parent.text
        color: Colors.deep_indigo_text_color
        opacity: isOnboardingState ? 1.0 : (parent.pressed || !parent.enabled) ? 0.7 : 1.0
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
