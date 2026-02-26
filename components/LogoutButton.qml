import QtQuick
import Quickshell.Io

QtObject {
    id: button
    required property string command
    required property string text
    property var keybind: null

    readonly property var process: Process {
        command: ["bash", "-c", button.command]
    }

    function exec() {
        process.startDetached();
        Qt.quit();
    }
}
