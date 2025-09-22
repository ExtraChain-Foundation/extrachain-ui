import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import ExtraChain 1.0

Item {
    id: root
    width: size
    height: cl.implicitHeight + 20

    property string icon: IcoMoon.bookmark
    property int size: 102
    property real koef_icon_size: 1.0
    property bool selected: false
    property QtObject style: Colors.button_square_default_style
    property color pressed_color: selected || m.pressed ? style.pressed_color_icon : Colors.grape_gray_color
    property color icon_color: style.color_icon
    property int rotation_icon: 0
    property string text
    property bool menu_button: false

    signal clicked()
    signal pressed()

    ColumnLayout {
        id: cl
        anchors.centerIn: parent
        width: parent.width
        height: implicitHeight
        spacing: 0

        Text {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignHCenter
            font.family: IcoMoon.iconmoon
            visible: parent.visible
            text: root.icon
            rotation: root.rotation_icon
            font.pixelSize: height * root.koef_icon_size
            color: root.pressed_color
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            opacity: m.pressed ? 0.7 : 1.0
        }

        MonserratText {
            Layout.preferredWidth: root.width
            Layout.preferredHeight: paintedHeight
            text: root.text
            elide: Text.ElideRight
            color: root.pressed_color
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 10
            visible: root.text.length > 0
            opacity: m.pressed ? 0.7 : 1.0
        }
    }

    MouseArea {
        id: m
        anchors.fill: parent
        anchors.margins: isMobile ? -10 : 0
        hoverEnabled: true
        propagateComposedEvents: true

        onClicked: root.clicked()
        onPressed: root.pressed()
    }
}
