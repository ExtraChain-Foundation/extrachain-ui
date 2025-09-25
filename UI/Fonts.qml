pragma Singleton

import QtQuick

QtObject {
    property string monserrat: monserratFontLoader.name
    property string dmsans: dmsansFontLoader.name
    property string sfpro: sfProFontLoader.name

    property FontLoader monserratFontLoader: FontLoader {
        source: "qrc:/fonts/UI/Fonts/Montserrat/static/Montserrat-Medium.ttf"
    }
    property FontLoader monserratFontBoldLoader: FontLoader {
        source: "qrc:/fonts/UI/Fonts/Montserrat/static/Montserrat-Bold.ttf"
    }
    property FontLoader dmsansFontLoader: FontLoader {
        source: "qrc:/fonts/UI/Fonts/DM_Sans/DMSans-VariableFont_opsz,wght.ttf"
    }

    property FontLoader sfProFontLoader: FontLoader {
        source: "qrc:/fonts/UI/Fonts/SFProDisplay/SFPRODISPLAYMEDIUM.OTF"
    }
}
