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

    readonly property var niriSetting: Process {}

    readonly property var windowSwitch: Process {}

    readonly property var workspaceSwitch: Process {}

    readonly property var closeWindow: Process {}

    readonly property var blueToothConnect: Process {}

    readonly property var blueToothDisconnect: Process {}

    readonly property var wifiConnectProcess: Process {}

    readonly property var wifiDisconnectProcess: Process {}

    readonly property var setStruts: Process {}

    function setStrutsExec(left) {
        setStruts.exec(["python3", Config.shellDir + "/scripts/setStruts.py", left]);
    }

    function bluetoothDisconnect(address) {
        blueToothDisconnect.exec(["bluetoothctl", "remove", address]);
    }

    function bluetoothConnect(address) {
        blueToothConnect.exec(["bluetoothctl", "connect", address]);
    }

    function wifiConnect(ssid, password) {
        wifiConnectProcess.exec(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
    }

    function wifiDisconnect(ssid) {
        wifiDisconnectProcess.exec(["nmcli", "connection", "delete", ssid]);
    }

    function niriSettingExec(niriData) {
        let niriJson = JSON.stringify(niriData);
        niriSetting.exec(["python3", Config.shellDir + "/scripts/niriSetting.py", niriJson]);
    }

    function changeWallpaper(path) {
        switchWallpaper.exec(["awww", "img", "-t", "random", path]);
    }

    function focusWorkspace(id) {
        workspaceSwitch.exec(["niri", "msg", "action", "focus-workspace", id]);
    }

    function killWindow(windowId) {
        closeWindow.exec(["niri", "msg", "action", "close-window", "--id", windowId]);
    }

    function toggleWindowSwitch(windowId) {
        windowSwitch.exec(["niri", "msg", "action", "focus-window", "--id", windowId]);
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
