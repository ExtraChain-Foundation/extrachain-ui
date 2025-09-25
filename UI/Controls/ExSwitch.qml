import QtQuick
import QtQuick.Controls.Material
import ExtraChain 1.0

Switch {
    id: switchControl

    property int indicator_height: 20
    property int indicator_width: indicator_height * 1.8
    property int indicator_radius: indicator_height/2

    width: indicator_width
    height: indicator_height

    indicator: Rectangle {
        implicitWidth: indicator_width
        implicitHeight: indicator_height
        radius: indicator_radius
        color: Colors.switch_control.indicator_color
        antialiasing: true

        Rectangle {
            id: handle
            x: switchControl.checked ? parent.width - width : 0
            width: indicator_height
            height: indicator_height
            radius: indicator_height / 2
            color: switchControl.checked ? Colors.switch_control.handled : Colors.switch_control.unhandled

            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }
        }
    }
}
