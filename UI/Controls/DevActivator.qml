import QtQuick
import "../Controls"

Row {
    id: clickPattern

    property int step: 0
    property int clicks: 0

    MouseArea {
        width: parent.width / 2
        height: parent.height
        enabled: true
        onClicked: {
            if ((clickPattern.step == 0 && clickPattern.clicks < 2) || (clickPattern.step == 2 && clickPattern.clicks < 1)) {
                clickPattern.clicks++
                resetTimer.restart()

                if (clickPattern.step == 0 && clickPattern.clicks >= 2) {
                    clickPattern.step = 1
                    clickPattern.clicks = 0
                } else if (clickPattern.step == 2 && clickPattern.clicks >= 1) {
                    clickPattern.step = 3
                    clickPattern.clicks = 0
                }
            } else {
                clickPattern.clicks = 0
                clickPattern.step = 0
            }
        }
    }

    MouseArea {
        width: parent.width / 2
        height: parent.height
        x: parent.width / 2
        enabled: true
        onClicked: {
            if ((clickPattern.step == 1 && clickPattern.clicks < 2) || (clickPattern.step == 3 && clickPattern.clicks < 1)) {
                clickPattern.clicks++
                resetTimer.restart()

                if (clickPattern.step == 1 && clickPattern.clicks >= 2) {
                    clickPattern.step = 2
                    clickPattern.clicks = 0
                } else if (clickPattern.step == 3 && clickPattern.clicks >= 1) {
                    root.reverseDevMode()
                }
            } else {
                clickPattern.clicks = 0
                clickPattern.step = 0
            }
        }
    }

    Timer {
        id: resetTimer
        interval: 1000
        running: clickPattern.step > 0 || clickPattern.clicks > 0
        onTriggered: {
            clickPattern.clicks = 0
            clickPattern.step = 0
        }
    }
}
