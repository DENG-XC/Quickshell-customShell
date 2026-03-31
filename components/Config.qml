pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "../js/ParseWindows.js" as ParseWindows
import "../js/UpdateFilter.js" as UpdateFilter
import "../js/UpdateRunningWindows.js" as UpdateRunningWindows

Singleton {
    id: config

    // ===== 缩放因子配置 =====
    // 基准分辨率（2K: 2560x1440）
    readonly property int baseWidth: 2560
    readonly property int baseHeight: 1440

    // 当前屏幕尺寸（需要在使用时传入 Screen.width/height）
    property int screenWidth: 2560  // 默认值，避免热重载后为 0
    property int screenHeight: 1440  // 默认值，避免热重载后为 0

    // 缩放因子
    readonly property real scaleFactor: Math.min(screenWidth / baseWidth, screenHeight / baseHeight)

    // 缩放函数
    function sc(value) {
        return Math.round(value * scaleFactor);
    }

    // 字体缩放函数（保证最小可读性）
    function scFont(baseSize) {
        return Math.max(10, Math.round(baseSize * scaleFactor));
    }
    // ===== 缩放因子配置结束 =====

    property color text: "#e6eaf0"//"#ffffff"
    property color textHover: "#65798b"
    property color progressColor: "#333b45"
    property color background: "#0f1115"//"#1e2127"
    property color foreground: "#181b21"//"#282b31"
    property color closeColor: "#e06c75"//"#ff5652"
    property color expandedColor: "#e5c07b"//"#ffbd2f"
    property color textselect: "#293038"//"#333B45"
    property color pinColor: "#98c379"//"#33C831"
    property int topbarwidth: 40
    property int gaps: 20
    property bool expandopen: false
    property int countWorkspace: 0
    property int currentworkspace: 0
    property int hoveredWorkspace: -1
    property int currentAppIndex: 0
    property int currentClipboardIndex: 0
    property string queryText: ""
    property bool notify: false
    property bool notifyVisible: false
    property bool calendarVisible: false
    property bool logoutVisible: false
    property bool lockVisible: false
    property bool clipboardVisible: false
    property bool toggleClipboard: false
    property bool toggleLeftPanel: false
    property bool toggleAppLauncher: false
    property bool toggleCollapseApp: false
    // property bool configPanelVisible: false
    // property bool wifiPasswordPopupVisible: false
    // property var selectedWifi: null
    property bool killLoader: false
    property string fontFamily: "JetBrains Mono Nerd Font 10"
    property string userName: ""
    property string shellDir: ""
    property string priScreen: ""
    property string workspacesOutput: ""
    property var filteredAppsModel: []
    // property var niriInfo: null

    onCurrentworkspaceChanged: hoveredWorkspace = -1

    property Timer windowsprocTimer: Timer {
        interval: 350
        running: config.toggleLeftPanel
        repeat: true
        onTriggered: windowsproc.running = true
    }

    property Timer countWorkspaceTimer: Timer {
        interval: 350
        running: config.toggleLeftPanel
        repeat: true
        onTriggered: countwsproc.running = true
    }

    property Timer appLauncherTimer: Timer {
        interval: 300
        running: false
        repeat: false
        onTriggered: {
            config.toggleAppLauncher = true;
        }
    }

    property Timer delayLoader: Timer {
        interval: 150
        running: false
        repeat: false
        onTriggered: {
            Config.killLoader = false;
        }
    }

    property alias runningWindowsModel: runningWindowsModelInternal
    ListModel {
        id: runningWindowsModelInternal
    }

    property alias notificationModel: notificationModelInternal
    ListModel {
        id: notificationModelInternal
    }

    property alias listPopupModel: listPopupModelInternal
    ListModel {
        id: listPopupModelInternal
        onCountChanged: {
            if (listPopupModel.count === 0) {
                config.notifyVisible = false;
            }
        }
    }

    NotificationServer {
        id: notifServer
        onNotification: function updateNotification(notification) {
            function pad(n) {
                return n < 10 ? "0" + n : n;
            }
            config.notifyVisible = true;
            let d = new Date();
            let now = pad(d.getHours()) + ":" + pad(d.getMinutes());
            let displayIcon = notification.appIcon || notification.image || "";

            notificationModel.insert(0, {
                icon: displayIcon,
                appName: notification.appName,
                summary: notification.summary,
                image: notification.image,
                body: notification.body,
                time: now
            });

            listPopupModel.insert(0, {
                icon: displayIcon,
                appName: notification.appName,
                summary: notification.summary,
                image: notification.image,
                body: notification.body,
                time: now
            });
        }
    }

    Component.onCompleted: {
        UpdateFilter.updateFilter("");
    }

    Process {
        id: windowsproc
        command: ["niri", "msg", "windows"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                ParseWindows.parseWindowsOutput(this.text, runningWindowsModel);
            }
        }
    }

    Process {
        id: countwsproc
        command: ["niri", "msg", "workspaces"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();

                function countWorkspaces(text) {
                    let lines = text.split("\n");

                    let inBlock = false;
                    let count = 0;
                    let focusedWs = 0;

                    for (let i = 0; i < lines.length; i++) {
                        let line = lines[i].trim();

                        if (line.includes('"' + config.priScreen + '"')) {
                            inBlock = true;
                            continue;
                        } else if (line === "" && inBlock) {
                            break;
                        } else if (inBlock) {
                            if (line.startsWith("*")) {
                                let pattern = /\*\s*(\d+)/;
                                let match = line.match(pattern);
                                if (match) {
                                    let wsNum = parseInt(match[1]);
                                    focusedWs = wsNum;
                                    count++;
                                }
                            } else {
                                count++;
                            }
                        }
                    }

                    config.currentworkspace = Math.max(1, focusedWs);
                    config.countWorkspace = Math.max(1, count);
                }

                if (text === config.workspacesOutput) {
                    return;
                }

                config.workspacesOutput = text;
                countWorkspaces(text);
            }
        }
    }

    Process {
        id: homedirproc
        command: ["whoami"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                config.userName = text;
                config.shellDir = "/home/" + text + "/.config/quickshell";
            }
        }
    }

    property alias priscreenproc: priscreenproc

    // 获取逻辑分辨率（scale 后的尺寸）
    Process {
        id: priscreenproc
        command: ["niri", "msg", "-j", "focused-output"]
        running: true  // 启动时运行，热重载后也会重新运行
        stdout: StdioCollector {
            onStreamFinished: {
                let output = JSON.parse(this.text);
                if (output && output.name) {
                    config.priScreen = output.name;
                    config.screenWidth = output.modes[output.current_mode].width;
                    config.screenHeight = output.modes[output.current_mode].height;
                }
            }
        }
    }

    // 获取 niri 配置信息（用于 AppearancePanel）
    // Process {
    //     id: niriInfoProc
    //     command: ["bash", "-c", "python3 ~/.config/quickshell/scripts/niriInfo.py"]
    //     running: true
    //     stdout: StdioCollector {
    //         onStreamFinished: {
    //             let text = JSON.parse(this.text);
    //             config.niriInfo = text;

    //             更新主屏幕名称
    //             for (let i = 0; i < text.screens.length; i++) {
    //                 if (text.screens[i].focus === true) {
    //                     config.priScreen = text.screens[i].name;
    //                     break;
    //                 }
    //             }
    //             if (!config.priScreen && text.screens.length > 0) {
    //                 config.priScreen = text.screens[0].name;
    //             }

    //             触发 priscreenproc 获取逻辑分辨率
    //             priscreenproc.running = true;
    //         }
    //     }
    // }
}
