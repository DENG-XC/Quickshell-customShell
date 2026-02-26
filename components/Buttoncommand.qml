pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: buttoncommand

    readonly property var overview: Process {
        command: ["niri", "msg", "action", "toggle-overview"]
    }

    readonly property var upWorkspace: Process {
        command: ["niri", "msg", "action", "focus-workspace-up"]
    }

    readonly property var downWorkspace: Process {
        command: ["niri", "msg", "action", "focus-workspace-down"]
    }

    readonly property var switchWallpaper: Process {}

    readonly property var windowSwitch: Process {}

    readonly property var workspaceSwitch: Process {}

    readonly property var closeWindow: Process {}

    function changeWallpaper(path) {
        switchWallpaper.exec(["swww", "img", "-t", "random", path])
    }

    function focusWorkspace(id) {
        workspaceSwitch.exec(["niri", "msg", "action", "focus-workspace", id.toString()]);
    }

    function killWindow(windowId) {
        closeWindow.exec(["niri", "msg", "action", "close-window", "--id", windowId.toString()]);
    }

    function toggleWindowSwitch(windowId) {
        windowSwitch.exec(["niri", "msg", "action", "focus-window", "--id", windowId.toString()]);
    }

    function toggleDownWorkspace() {
        downWorkspace.startDetached();
    }

    function toggleUpWorkspace() {
        upWorkspace.startDetached();
    }

    function toggleOverview() {
        overview.startDetached();
    }
}
