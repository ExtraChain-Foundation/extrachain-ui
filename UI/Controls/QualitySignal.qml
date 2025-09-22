import QtQuick
import QtQuick.Controls.Material
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Effects
import ExtraChain 1.0

import "../Controls"
import "../Fonts"

Item {
    id: qualitySignalItem

    width: 40
    height: 40
    property int qualityModel: 3
    onQualityModelChanged: changeColorSignalQuality()

    property var excelent_quality: [ Colors.quality_signal.excelent_quality_begin, Colors.quality_signal.excelent_quality_end ]
    property var good_quality: [ Colors.quality_signal.good_quality, Colors.quality_signal.good_quality ]
    property var bad_quality: [ Colors.quality_signal.bad_quality, Colors.quality_signal.bad_quality ]
    property var colorQuality: excelent_quality
    property bool isShowPing: false
    property int pingMs: 87

    function changeColorSignalQuality() {
        if(qualityModel === 3)
            colorQuality =  excelent_quality
        if(qualityModel === 2)
            colorQuality =  good_quality
        if(qualityModel === 1)
            colorQuality = bad_quality
    }

    ColumnLayout {
        anchors.fill: parent
        
        Item {
            id: signalItem
            Layout.preferredHeight: 24
            Layout.fillWidth: true
            Component.onCompleted: changeColorSignalQuality()
            
            Row {
                height: parent.height
                width: implicitWidth
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2
                
                Repeater {
                    rotation: 180
                    model: 3
                    Rectangle {
                        width: 4; height: ((signalItem.height /3) * (index + 1))
                        y: signalItem.height - height
                        
                        radius: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: ((index +1) <= qualitySignalItem.qualityModel) ? qualitySignalItem.colorQuality[0] : Colors.quality_signal.signal_color
                            }
                            GradientStop {
                                position: 1.0
                                color: ((index +1) <= qualitySignalItem.qualityModel) ? qualitySignalItem.colorQuality[1] : Colors.quality_signal.signal_color
                            }
                        }
                    }
                }
            }
        }
        
        DmsansText {
            Layout.preferredHeight: 10
            Layout.fillWidth: true
            text: pingMs + " ms"
            font.pixelSize: 12
            color: Colors.mining_text_color
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            visible: isShowPing
        }
    }
}
