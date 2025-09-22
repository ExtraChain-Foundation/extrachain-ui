import QtQuick


SequentialAnimation {
    id: colorFlashAnimation
    running: false
    loops: 1
    property int duration_out: 250
    property int duration_in:  400
    property string color_in
    property var _target
    
    ColorAnimation {
        target: _target
        property: "color"
        to: adjustBrightness(color_in, 50)
        duration: duration_out
        easing.type: Easing.OutQuad
    }
    
    ColorAnimation {
        target: _target
        property: "color"
        to: color_in
        duration: duration_in
        easing.type: Easing.InQuad
    }
}
