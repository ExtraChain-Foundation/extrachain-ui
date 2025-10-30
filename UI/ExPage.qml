import QtQuick
import QtQuick.Controls.Material

Rectangle {
    anchors.fill: parent
    color: Colors.background
    property bool activeAnimation: false
    property bool useShadow: true
    property alias meshVisible: mesh.visible

    MouseArea {
        anchors.fill: parent
        onPressed: if (isDesktop) root.startSystemMove()
    }

    Canvas {
        id: mesh
        anchors.fill: parent
        visible: false
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            ctx.strokeStyle = Colors.border_color;
            ctx.lineWidth = 1;

            for (var x = 0; x <= width; x += 27) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, height);
                ctx.stroke();
            }

            for (var y = 0; y <= height; y += 27) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Rectangle {
        height: parent.height * 0.3
        width: parent.width
        visible: useShadow
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Colors.background
            }
            GradientStop {
                position: 1.0
                color: Colors.background_start
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        height: parent.height * 0.3
        width: parent.width
        visible: useShadow
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Colors.background_start
            }
            GradientStop {
                position: 1.0
                color: Colors.background
            }
        }
    }

    // Item {
    //     width: parent.width
    //     height: parent.height
    //     x: 120
    //     y: 20

    //     Image {
    //         anchors.centerIn: parent
    //         source: Colors.isDarkTheme ?  "qrc:/new_design/UI/Images/new_design/dark_blue_shadow.svg" : "qrc:/new_design/UI/Images/new_design/light_blue_shadow.svg"
    //     }

    //     SequentialAnimation on x {
    //         running: activeAnimation
    //         loops: Animation.Infinite
    //         NumberAnimation { to: -120; duration: 5000; easing.type: Easing.InOutQuad }
    //         NumberAnimation { to: 120; duration: 4000; easing.type: Easing.InOutQuad }
    //     }

    //     SequentialAnimation on y {
    //         loops: Animation.Infinite
    //         running: activeAnimation
    //         NumberAnimation { to: -20; duration: 6000; easing.type: Easing.InOutQuad }
    //         NumberAnimation { to: 20; duration: 3000; easing.type: Easing.InOutQuad }
    //     }
    // }

    Item {
        width: 500
        height: 1000
        x: (parent.width - (width/2))
        y: (parent.y - (height/2))
        rotation: -30
        visible: false//isDesktop


        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: Colors.extrachain_page.gradient_begin
                }
                GradientStop {
                    position: 1.0
                    color: Colors.extrachain_page.gradient_end
                }
            }
        }
    }
}

