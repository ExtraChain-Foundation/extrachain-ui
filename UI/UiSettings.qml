pragma Singleton

import QtQuick

QtObject {
    readonly property bool visible_select_network: !etUtils.isRelease
    property bool visible_indicator_connection: debugMode
    property bool allow_jump_to_folder: !etUtils.isRelease
    property bool debugMode: !etUtils.isRelease && Qt.platform.os !== "ios"
}
